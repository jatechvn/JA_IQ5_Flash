// lib/modules/ui/main_window.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../i18n.dart';
import '../ja_license_checker.dart';
import '../utils.dart';
import '../logic/device_manager.dart';
import '../logic/flash_session.dart';
import '../logic/firmware_slot.dart';
import '../logic/reboot_worker.dart';
import '../logic/fastboot_to_edl_worker.dart';
import 'styles.dart';
import 'app_colors.dart';
import 'dialogs.dart';
import 'device_card.dart';
import 'adb_device_card.dart';
import 'glass_widgets.dart';
import 'settings_dialog.dart';

class MainWindow extends StatefulWidget {
  final AppTheme theme;
  const MainWindow({super.key, required this.theme});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  // Session lists
  final Map<String, FlashSession> _sessions = {}; // COM port -> FlashSession
  final Map<String, String> _adbStatus =
      {}; // Serial -> 'idle' | 'waiting' | 'success' | 'error'

  final List<String> _globalLogs = [];
  final ScrollController _globalLogController = ScrollController();

  late DeviceManager _deviceManager;
  Timer? _devicePollTimer;
  Timer? _licenseRefreshTimer;

  // 3 Smart Firmware Slots
  late final List<FirmwareSlotProfile> _slots;
  int _activeFwSlot = 0;
  String _fwDir = defaultFwDir;

  bool _autoFlash = false;

  // Auto-flash tracking structures
  final Map<String, int> _autoProcessed = {}; // Serial -> timestamp
  final Set<String> _flashCycled = {};
  int _expectingAdbFromReboot = 0;

  // Worker references to allow aborting
  final Map<String, RebootWorker> _rebootWorkers = {};
  final Map<String, FastbootToEdlWorker> _fastbootWorkers = {};

  LicenseInfo? _licenseInfo;
  IOSink? _logFileSink;
  late final TextEditingController _pathController;
  int _terminalHeightMode =
      1; // 0: collapsed (34px), 1: compact (92px), 2: expanded (170px)

  @override
  void initState() {
    super.initState();
    widget.theme.addListener(_onThemeChanged);
    _initSlots();
    _initLogFile();
    _pathController = TextEditingController(text: _fwDir);
    _loadConfig();
    _checkLicense();

    _deviceManager = DeviceManager(
      onDeviceAdded: _onDeviceAdded,
      onDeviceRemoved: _onDeviceRemoved,
      onAdbDevicesChanged: _onAdbDevicesChanged,
    );

    // Scan timers
    _devicePollTimer = Timer.periodic(const Duration(milliseconds: 2000), (
      timer,
    ) {
      _deviceManager.poll();
      _runAutoPipeline();
    });

    _licenseRefreshTimer = Timer.periodic(const Duration(hours: 4), (timer) {
      _checkLicense();
    });

    // Initial scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deviceManager.poll();
      _appendGlobalLog(tr('log_app_started'), 'info');
    });
  }

  @override
  void didUpdateWidget(MainWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      oldWidget.theme.removeListener(_onThemeChanged);
      widget.theme.addListener(_onThemeChanged);
    }
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _initSlots() {
    _slots = [
      FirmwareSlotProfile(
        index: 0,
        type: FirmwareSlotType.factory,
        customName: '',
        path: defaultFwDir,
      ),
      FirmwareSlotProfile(
        index: 1,
        type: FirmwareSlotType.user,
        customName: '',
        path: defaultFwDir,
      ),
      FirmwareSlotProfile(
        index: 2,
        type: FirmwareSlotType.diag,
        customName: '',
        path: defaultFwDir,
      ),
    ];
  }

  @override
  void dispose() {
    widget.theme.removeListener(_onThemeChanged);
    _devicePollTimer?.cancel();
    _licenseRefreshTimer?.cancel();
    _deviceManager.dispose();
    for (final session in _sessions.values) {
      session.dispose();
    }
    for (final worker in _rebootWorkers.values) {
      worker.abort();
    }
    for (final worker in _fastbootWorkers.values) {
      worker.abort();
    }
    _globalLogController.dispose();
    _pathController.dispose();
    _logFileSink?.flush();
    _logFileSink?.close();
    super.dispose();
  }

  // ── Config loader & Saver ──────────────────────────────────────────
  void _loadConfig() {
    try {
      final configFile = File(p.join(baseDir, 'config.ini'));
      if (configFile.existsSync()) {
        final content = configFile.readAsStringSync();
        final config = IniConfig()..load(content);

        // Active slot
        _activeFwSlot =
            (int.tryParse(config.get('PATHS', 'active_fw_slot', '0')) ?? 0)
                .clamp(0, 2);

        // Slot paths
        _slots[0].path = config.get('PATHS', 'firmware_slot_0', defaultFwDir);
        _slots[1].path = config.get('PATHS', 'firmware_slot_1', defaultFwDir);
        _slots[2].path = config.get('PATHS', 'firmware_slot_2', defaultFwDir);

        // Slot custom names if saved (empty string if not customized)
        _slots[0].customName = config.get('PATHS', 'slot_0_name', '');
        _slots[1].customName = config.get('PATHS', 'slot_1_name', '');
        _slots[2].customName = config.get('PATHS', 'slot_2_name', '');

        // Slot types if saved
        _slots[0].type = FirmwareSlotType.fromId(
          config.get('PATHS', 'slot_0_type', 'factory'),
        );
        _slots[1].type = FirmwareSlotType.fromId(
          config.get('PATHS', 'slot_1_type', 'user'),
        );
        _slots[2].type = FirmwareSlotType.fromId(
          config.get('PATHS', 'slot_2_type', 'diag'),
        );

        _fwDir = _slots[_activeFwSlot].path;

        final lang = config.get('APP', 'language', 'VI');
        setLang(lang);

        final themeStr = config.get('APP', 'theme', 'dark');
        widget.theme.setTheme(themeStr == 'dark');

        final perfModeStr = config.get('GLASS', 'perf_mode', 'auto');
        widget.theme.setPerfTierMode(PerfTierMode.fromId(perfModeStr));

        // Glassmorphism settings
        final cardBlur =
            double.tryParse(config.get('GLASS', 'card_blur', '20.0')) ?? 20.0;
        final cardOpacity =
            double.tryParse(config.get('GLASS', 'card_opacity', '0.25')) ??
            0.25;
        final dialogBlur =
            double.tryParse(config.get('GLASS', 'dialog_blur', '20.0')) ?? 20.0;
        final dialogOpacity =
            double.tryParse(config.get('GLASS', 'dialog_opacity', '0.85')) ??
            0.85;
        final enableOrbs =
            config.get('GLASS', 'enable_mesh_orbs', 'true') == 'true';
        final orbOpacity =
            double.tryParse(config.get('GLASS', 'mesh_orb_opacity', '0.24')) ??
            0.24;
        widget.theme.setLiveGlassmorphism(
          cardBlur: cardBlur,
          cardOpacity: cardOpacity,
          dialogBlur: dialogBlur,
          dialogOpacity: dialogOpacity,
          enableMeshOrbs: enableOrbs,
          meshOrbOpacity: orbOpacity,
          notify: false,
        );
      }
    } catch (e) {
      _appendGlobalLog(
        tr('log_config_load_error').replaceAll('{err}', e.toString()),
        'error',
      );
    }
    _validateAllSlots();
    _pathController.text = _fwDir;
  }

  void _saveConfig() {
    try {
      final config = IniConfig();
      config.set('APP', 'language', getLang());
      config.set('APP', 'theme', widget.theme.isDark ? 'dark' : 'light');
      config.set('APP', 'compact', 'false');

      // Glassmorphism & Hardware Tier preferences
      config.set('GLASS', 'perf_mode', widget.theme.perfMode.id);
      config.set(
        'GLASS',
        'card_blur',
        widget.theme.cardBlur.toStringAsFixed(1),
      );
      config.set(
        'GLASS',
        'card_opacity',
        widget.theme.cardOpacity.toStringAsFixed(2),
      );
      config.set(
        'GLASS',
        'dialog_blur',
        widget.theme.dialogBlur.toStringAsFixed(1),
      );
      config.set(
        'GLASS',
        'dialog_opacity',
        widget.theme.dialogOpacity.toStringAsFixed(2),
      );
      config.set(
        'GLASS',
        'enable_mesh_orbs',
        widget.theme.enableMeshOrbs.toString(),
      );
      config.set(
        'GLASS',
        'mesh_orb_opacity',
        widget.theme.meshOrbOpacity.toStringAsFixed(2),
      );

      config.set('PATHS', 'active_fw_slot', _activeFwSlot.toString());
      config.set('PATHS', 'firmware_slot_0', _slots[0].path);
      config.set('PATHS', 'firmware_slot_1', _slots[1].path);
      config.set('PATHS', 'firmware_slot_2', _slots[2].path);
      config.set('PATHS', 'slot_0_name', _slots[0].customName);
      config.set('PATHS', 'slot_1_name', _slots[1].customName);
      config.set('PATHS', 'slot_2_name', _slots[2].customName);
      config.set('PATHS', 'slot_0_type', _slots[0].type.id);
      config.set('PATHS', 'slot_1_type', _slots[1].type.id);
      config.set('PATHS', 'slot_2_type', _slots[2].type.id);
      config.set('PATHS', 'firmware_dir', _fwDir);

      final configFile = File(p.join(baseDir, 'config.ini'));
      configFile.writeAsStringSync(config.save());
    } catch (e) {
      _appendGlobalLog(
        tr('log_config_save_error').replaceAll('{err}', e.toString()),
        'error',
      );
    }
  }

  void _validateAllSlots() {
    setState(() {
      for (final slot in _slots) {
        slot.validate();
      }
      _fwDir = _slots[_activeFwSlot].path;
    });
  }

  void _checkLicense() {
    setState(() {
      _licenseInfo = getLicenseInfo(appId);
    });
  }

  void _appendGlobalLog(String message, String level) {
    if (!mounted) return;
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      final formatted = '[$timestamp] [${level.toUpperCase()}] $message';
      _globalLogs.add(formatted);
      if (_globalLogs.length > 2000) {
        _globalLogs.removeRange(0, 500);
      }
      try {
        _logFileSink?.writeln(formatted);
      } catch (_) {}
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_globalLogController.hasClients) {
        _globalLogController.jumpTo(
          _globalLogController.position.maxScrollExtent,
        );
      }
    });
  }

  void _initLogFile() {
    try {
      final logsDir = Directory(p.join(baseDir, 'logs'));
      if (!logsDir.existsSync()) logsDir.createSync(recursive: true);
      final now = DateTime.now();
      final fileName =
          'session_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.log';
      final logFile = File(p.join(logsDir.path, fileName));
      _logFileSink = logFile.openWrite(mode: FileMode.writeOnlyAppend);
    } catch (_) {}
  }

  void _onDeviceAdded(DeviceInfo dev) {
    if (!mounted) return;
    _appendGlobalLog(
      tr('log_edl_detected').replaceAll('{port}', dev.port),
      'info',
    );
    setState(() {
      _sessions[dev.port] = FlashSession(
        device: dev,
        fwDir: _fwDir,
        onProgressChanged: (port, pct) {},
        onLogMessage: (port, msg, lvl) {
          _appendGlobalLog(msg, lvl);
        },
        onDone: (port, ok, summary) {
          if (!mounted) return;
          final resStr = ok ? tr('success') : '${tr('failed')} - $summary';
          _appendGlobalLog(
            tr(
              'log_device_flash_done',
            ).replaceAll('{port}', port).replaceAll('{result}', resStr),
            ok ? 'success' : 'error',
          );
          if (_autoFlash && ok) {
            _expectingAdbFromReboot++;
          }
        },
      );
    });

    if (_autoFlash) {
      _startFlash(dev.port);
    }
  }

  void _onDeviceRemoved(String port) {
    if (!mounted) return;
    _appendGlobalLog(
      tr('log_edl_disconnected').replaceAll('{port}', port),
      'warn',
    );
    setState(() {
      _sessions.remove(port);
      _rebootWorkers[port]?.abort();
      _rebootWorkers.remove(port);
    });
  }

  void _onAdbDevicesChanged(List<AdbDevice> list) {
    if (!mounted) return;
    setState(() {
      final activeSerials = list.map((d) => d.serial).toSet();
      _adbStatus.removeWhere((key, value) => !activeSerials.contains(key));

      for (final dev in list) {
        if (!_adbStatus.containsKey(dev.serial)) {
          _adbStatus[dev.serial] = 'idle';
        }
      }
    });
  }

  // ── Flashing operations ────────────────────────────────────
  Future<void> _startFlash(String port) async {
    final session = _sessions[port];
    if (session == null ||
        session.isRunning ||
        _rebootWorkers.containsKey(port)) {
      return;
    }

    final activeSlot = _slots[_activeFwSlot];
    if (!activeSlot.validate().isValid) {
      showAlertDialog(
        context: context,
        title: tr('fw_missing'),
        content:
            '${activeSlot.displayName}: ${activeSlot.lastValidation.detailMessage}\n\n${tr('err_select_valid_fw')}',
        theme: widget.theme,
      );
      return;
    }

    _appendGlobalLog(
      '${tr('log_flash_start').replaceAll('{port}', port)} [Slot ${_activeFwSlot + 1}: ${activeSlot.displayName}]',
      'info',
    );
    await session.start(firmwareDirectory: activeSlot.path.trim());
  }

  void _abortFlash(String port) {
    final session = _sessions[port];
    if (session == null) return;
    _appendGlobalLog(tr('log_flash_abort').replaceAll('{port}', port), 'warn');
    session.abort();
  }

  void _startFlashAll() {
    if (_sessions.isEmpty) {
      _appendGlobalLog(tr('log_flash_no_devices'), 'warn');
      return;
    }
    for (final port in _sessions.keys) {
      _startFlash(port);
    }
  }

  void _abortAll() {
    for (final port in _sessions.keys) {
      _abortFlash(port);
    }
    for (final worker in _fastbootWorkers.values) {
      worker.abort();
    }
    for (final worker in _rebootWorkers.values) {
      worker.abort();
    }
  }

  // ── Reboot operations ─────────────────────────────────────
  Future<void> _runRebootWorker(String port) async {
    if (_rebootWorkers.containsKey(port) ||
        (_sessions[port]?.isRunning ?? false)) {
      return;
    }

    _appendGlobalLog(tr('log_reboot_start').replaceAll('{port}', port), 'info');
    final worker = RebootWorker(port: port, fwDir: _fwDir);
    _rebootWorkers[port] = worker;

    setState(() {
      _sessions[port]?.setStatus('rebooting');
    });

    final (success, msg) = await worker.run(
      onLog: (line, level) {
        if (!mounted) return;
        _sessions[port]?.appendLog(line, level);
        _appendGlobalLog(line, level);
      },
    );

    if (!mounted) return;
    if (success) {
      _expectingAdbFromReboot++;
    }

    setState(() {
      _rebootWorkers.remove(port);
      _sessions[port]?.setStatus(
        success ? FlashSession.statusSuccess : FlashSession.statusError,
      );
    });
  }

  // ── Fastboot -> ADB -> EDL pipeline ──────────────────────────
  Future<void> _runFastbootToEdlWorker(String serial) async {
    if (_fastbootWorkers.containsKey(serial)) return;

    _appendGlobalLog(
      tr('log_auto_pipe_start').replaceAll('{serial}', serial),
      'info',
    );
    final worker = FastbootToEdlWorker(
      serial: serial,
      onStep: (s, msg, lvl) {
        _appendGlobalLog(msg, lvl);
      },
      onAdbAppeared: (adbSerial) {
        _flashCycled.add(adbSerial);
      },
      onDone: (s, ok, msg) {
        if (!mounted) return;
        setState(() {
          _adbStatus[serial] = ok ? 'success' : 'error';
          _fastbootWorkers.remove(serial);
        });
      },
      onNeedTestpoint: (s) {
        _appendGlobalLog(
          tr('fb_testpoint_log').replaceAll('{serial}', s),
          'error',
        );
      },
    );

    _fastbootWorkers[serial] = worker;
    setState(() {
      _adbStatus[serial] = 'waiting';
    });

    await worker.run(_deviceManager);
  }

  // ── Auto Pipeline Coordinator ──────────────────────────────
  void _runAutoPipeline() {
    if (!_autoFlash) return;

    // 1. Skip fastboot devices in Auto mode
    for (final dev in _deviceManager.knownAdb) {
      if (dev.isFastboot) {
        final serial = dev.serial;
        final status = _adbStatus[serial] ?? 'idle';
        if (status == 'idle' && !_flashCycled.contains(serial)) {
          setState(() {
            _adbStatus[serial] = 'error';
            _flashCycled.add(serial);
          });
          _appendGlobalLog(
            '❌ [AUTO] Fastboot device detected: $serial — skipped.',
            'error',
          );
        }
      }
    }

    // 2. Process ADB devices
    for (final dev in _deviceManager.knownAdb) {
      if (!dev.isFastboot && dev.state == 'device') {
        final serial = dev.serial;
        final status = _adbStatus[serial] ?? 'idle';

        if (_expectingAdbFromReboot > 0) {
          _expectingAdbFromReboot--;
          _adbStatus[serial] = 'success';
          _flashCycled.add(serial);
          _appendGlobalLog(
            tr('log_flash_success_reboot').replaceAll('{serial}', serial),
            'success',
          );
          continue;
        }

        if (status == 'idle' && !_flashCycled.contains(serial)) {
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final lastProcessed = _autoProcessed[serial] ?? 0;
          if (now - lastProcessed > 120) {
            _autoProcessed[serial] = now;
            _triggerAdbRebootEdl(serial);
          }
        }
      }
    }
  }

  Future<void> _triggerAdbRebootEdl(String serial) async {
    _appendGlobalLog(
      tr('adb_rebooting_log').replaceAll('{serial}', serial),
      'info',
    );
    setState(() {
      _adbStatus[serial] = 'waiting';
    });

    try {
      final res = await Process.run(adbExePath, [
        '-s',
        serial,
        'reboot',
        'edl',
      ]);
      if (!mounted) return;
      final ok = res.exitCode == 0;
      if (!ok) {
        _appendGlobalLog(
          tr(
            'err_adb_reboot_failed',
          ).replaceAll('{err}', res.stderr.toString().trim()),
          'error',
        );
      }
      setState(() {
        _adbStatus[serial] = ok ? 'success' : 'error';
      });
    } catch (e) {
      if (!mounted) return;
      _appendGlobalLog(
        tr('err_adb_reboot_failed').replaceAll('{err}', e.toString()),
        'error',
      );
      setState(() {
        _adbStatus[serial] = 'error';
      });
    }
  }

  void _updateActiveSlotPath(String newPath) {
    var cleanPath = newPath.trim();
    // Strip wrapping double or single quotes if copied as path
    if ((cleanPath.startsWith('"') && cleanPath.endsWith('"')) ||
        (cleanPath.startsWith("'") && cleanPath.endsWith("'"))) {
      if (cleanPath.length >= 2) {
        cleanPath = cleanPath.substring(1, cleanPath.length - 1).trim();
      }
    }
    if (cleanPath.isEmpty) return;

    setState(() {
      _slots[_activeFwSlot].path = cleanPath;
      _fwDir = cleanPath;
      _pathController.text = cleanPath;
    });
    _validateAllSlots();
    _saveConfig();
    _appendGlobalLog(
      '${tr('log_slot_update_prefix')} ${_activeFwSlot + 1}: $cleanPath',
      'info',
    );
  }

  Future<void> _pastePathFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _updateActiveSlotPath(text);
    }
  }

  Future<void> _selectFirmwareFolder() async {
    final path = await selectDirectory(
      initialDirectory: _fwDir,
      dialogTitle: '${tr('change_btn')} - Slot ${_activeFwSlot + 1}',
    );
    if (!mounted) return;
    if (path != null && path.isNotEmpty) {
      _updateActiveSlotPath(path);
    }
  }

  void _switchFwSlot(int slotIdx) {
    if (slotIdx < 0 || slotIdx >= _slots.length) return;
    setState(() {
      _activeFwSlot = slotIdx;
      _fwDir = _slots[slotIdx].path;
      _pathController.text = _fwDir;
    });
    _validateAllSlots();
    _saveConfig();
    _appendGlobalLog(
      '${tr('log_slot_switch').replaceAll('{slot}', (slotIdx + 1).toString())} [${_slots[slotIdx].displayName}]',
      'info',
    );
  }

  void _revealActiveFolder() {
    final dir = Directory(_fwDir);
    if (!dir.existsSync()) {
      _appendGlobalLog(
        tr('log_folder_not_exist').replaceAll('{dir}', _fwDir),
        'warn',
      );
      return;
    }
    Process.run('explorer.exe', [dir.absolute.path]);
  }

  Future<void> _renameSlot(int slotIndex) async {
    final slot = _slots[slotIndex];
    final c = widget.theme.colors;
    final controller = TextEditingController(text: slot.displayName);
    var selectedType = slot.type;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Dialog(
                backgroundColor: c.headerBg.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: c.borderDefault, width: 1.2),
                ),
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 24,
                ),
                child: Container(
                  width: 480,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Icon & Close
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedType.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedType.color.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.drive_file_rename_outline_rounded,
                              size: 20,
                              color: selectedType.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(
                                    'rename_slot_title',
                                  ).replaceAll('{slot}', '${slotIndex + 1}'),
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr('rename_slot_subtitle'),
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            color: c.textSecondary,
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Text Field
                      Text(
                        tr('rename_slot_name_label'),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: tr('rename_slot_hint'),
                          hintStyle: TextStyle(
                            color: c.textMuted,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: c.subCardBg,
                          prefixIcon: Icon(
                            selectedType.icon,
                            color: selectedType.color,
                            size: 18,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: selectedType.color,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Preset Chips (1-Click)
                      Text(
                        tr('rename_slot_presets_header'),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _presetChip(
                            label: '🏭 ${tr('slot_factory_rom')}',
                            onTap: () {
                              setDlgState(() {
                                controller.text = tr('slot_factory_rom');
                                selectedType = FirmwareSlotType.factory;
                              });
                            },
                            c: c,
                          ),
                          _presetChip(
                            label: '👤 ${tr('slot_user_rom')}',
                            onTap: () {
                              setDlgState(() {
                                controller.text = tr('slot_user_rom');
                                selectedType = FirmwareSlotType.user;
                              });
                            },
                            c: c,
                          ),
                          _presetChip(
                            label: '🛠️ ${tr('slot_diag_rom')}',
                            onTap: () {
                              setDlgState(() {
                                controller.text = tr('slot_diag_rom');
                                selectedType = FirmwareSlotType.diag;
                              });
                            },
                            c: c,
                          ),
                          _presetChip(
                            label: '🚑 ${tr('preset_unbrick')}',
                            onTap: () {
                              setDlgState(() {
                                controller.text = tr('preset_unbrick');
                              });
                            },
                            c: c,
                          ),
                          _presetChip(
                            label: '🌐 ${tr('preset_global')}',
                            onTap: () {
                              setDlgState(() {
                                controller.text = tr('preset_global');
                              });
                            },
                            c: c,
                          ),
                          _presetChip(
                            label: '🧪 ${tr('preset_qa_test')}',
                            onTap: () {
                              setDlgState(() {
                                controller.text = tr('preset_qa_test');
                              });
                            },
                            c: c,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ROM Type Selector
                      Text(
                        tr('rename_slot_type_header'),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: FirmwareSlotType.values.map((type) {
                          final isTypeSelected = selectedType == type;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: InkWell(
                                onTap: () {
                                  setDlgState(() {
                                    selectedType = type;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isTypeSelected
                                        ? type.color.withValues(alpha: 0.18)
                                        : c.subCardBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isTypeSelected
                                          ? type.color
                                          : c.subCardBorder,
                                      width: isTypeSelected ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        type.icon,
                                        size: 14,
                                        color: isTypeSelected
                                            ? type.color
                                            : c.textSecondary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        type.localizedBadge,
                                        style: TextStyle(
                                          color: isTypeSelected
                                              ? type.color
                                              : c.textSecondary,
                                          fontSize: 9.5,
                                          fontWeight: isTypeSelected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.textSecondary,
                              side: BorderSide(color: c.borderDefault),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              tr('cancel'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedType.color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              tr('save_slot_name'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result == true) {
      final text = controller.text.trim();
      setState(() {
        if (text.isNotEmpty) {
          slot.customName = text;
        }
        slot.type = selectedType;
      });
      _saveConfig();
      _appendGlobalLog(
        tr('log_slot_renamed')
            .replaceAll('{slot}', '${slotIndex + 1}')
            .replaceAll('{name}', slot.displayName)
            .replaceAll('{type}', slot.type.localizedBadge),
        'info',
      );
    }
  }

  Widget _presetChip({
    required String label,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.subCardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.subCardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _renameActiveSlot() async {
    await _renameSlot(_activeFwSlot);
  }

  void _copyAllLogs() {
    if (_globalLogs.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _globalLogs.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('logs_copied')),
        duration: const Duration(seconds: 2),
        backgroundColor: widget.theme.colors.accentEmerald,
      ),
    );
  }

  void _clearLogs() {
    setState(() {
      _globalLogs.clear();
    });
  }

  void _cyclePerfTier() {
    setState(() {
      widget.theme.cyclePerfTier();
    });
    _saveConfig();
    final lang = getLang();
    final t = widget.theme;
    String msg;
    if (lang == 'EN') {
      msg =
          '⚡ Graphic Tier: ${t.perfLabel} (Optimized for ${t.cpuCores} CPU Cores)';
    } else if (lang == 'CN') {
      msg =
          '⚡ 硬件档位: ${t.perfLabel} (针对 ${t.cpuCores} 核处理器优化)';
    } else {
      msg =
          '⚡ Cấu hình máy: ${t.perfLabel} (Tự động nhận diện CPU ${t.cpuCores} Cores)';
    }
    _appendGlobalLog(msg, 'info');
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(t.effectiveTier.icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        duration: const Duration(milliseconds: 1800),
        backgroundColor: t.effectiveTier.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _cycleLanguage() {
    final current = getLang();
    String next = 'EN';
    if (current == 'EN') {
      next = 'VI';
    } else if (current == 'VI') {
      next = 'CN';
    }
    setLang(next);
    _saveConfig();
    _checkLicense();
    _validateAllSlots();
    setState(() {});
    _appendGlobalLog(tr('log_lang_change').replaceAll('{lang}', next), 'info');
  }

  void _toggleTheme() {
    widget.theme.toggleTheme();
    _saveConfig();
    _appendGlobalLog(tr('log_theme_change'), 'info');
  }

  Future<void> _openSettings({int initialTab = 0}) async {
    final saved = await showSettingsDialog(
      context: context,
      theme: widget.theme,
      initialTab: initialTab,
      onConfigSaved: _saveConfig,
    );
    if (!mounted) return;
    if (saved == true) {
      _saveConfig();
      _appendGlobalLog(tr('log_settings_saved'), 'info');
    }
    _checkLicense();
  }

  Future<void> _openLicenseManager() async {
    await _openSettings(initialTab: 3);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final c = t.colors;
    final textTheme = t.themeData.textTheme;
    final activeSlot = _slots[_activeFwSlot];
    final activeValidation = activeSlot.lastValidation;

    // Status chip styling for active slot
    Color fwStatusColor = c.accentRose;
    String fwStatusText = activeValidation.localizedMessage;
    if (activeValidation.isValid) {
      fwStatusColor = c.accentEmerald;
      fwStatusText = '✅ ${activeValidation.localizedMessage}';
    } else if (activeValidation.statusKey == 'fw_missing') {
      fwStatusColor = c.accentAmber;
      fwStatusText = '⚠️ ${activeValidation.localizedMessage}';
    }

    return GlassScaffold(
      colors: c,
      enableMeshOrbs: t.enableMeshOrbs,
      orbOpacity: t.meshOrbOpacity,
      body: SafeArea(
        child: Column(
          children: [
            // ══════════════════════════════════════════════════════════════════
            //  1. TOP MODERN MENU BAR
            // ══════════════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: c.headerBg,
                border: Border(bottom: BorderSide(color: c.headerBorder)),
              ),
              child: Row(
                children: [
                  // App Brand Logo with subtle glow container
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.accentCyan, c.accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: c.primaryGlow.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title + Version Pill
                  Text(
                    appName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      fontSize: 16,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PillBadge(
                    label: 'v$appVersion',
                    color: c.accentCyan,
                    bg: c.accentCyan.withValues(alpha: 0.12),
                    border: c.accentCyan.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                  if (isCliDebug) ...[
                    const SizedBox(width: 8),
                    PillBadge(
                      label: 'DEBUG · v$appVersion (${getBuildTime()})',
                      icon: Icons.bug_report_rounded,
                      color: c.accentAmber,
                      bg: c.accentAmber.withValues(alpha: 0.15),
                      border: c.accentAmber.withValues(alpha: 0.4),
                      showDot: true,
                      fontSize: 10,
                    ),
                  ],
                  const SizedBox(width: 14),

                  // Active Firmware Profile Quick Indicator Pill
                  PillBadge(
                    label:
                        '${tr('slot_indicator_prefix')} ${_activeFwSlot + 1}: ${activeSlot.displayName}',
                    icon: activeSlot.type.icon,
                    color: activeSlot.type.color,
                    bg: activeSlot.type.color.withValues(alpha: 0.12),
                    border: activeSlot.type.color.withValues(alpha: 0.35),
                    showDot: true,
                    fontSize: 10,
                  ),

                  const Spacer(),

                  // 1. License Status Capsule with Hover Expand (Showcase Style)
                  if (_licenseInfo != null) ...[
                    Builder(
                      builder: (context) {
                        final isLicValid =
                            _licenseInfo!.valid && !_licenseInfo!.expired;
                        final licColor = isLicValid
                            ? c.accentEmerald
                            : c.accentRose;
                        return TopBarExpandingButton(
                          icon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: licColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: licColor.withValues(alpha: 0.6),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                isLicValid
                                    ? Icons.vpn_key_rounded
                                    : Icons.gpp_bad_rounded,
                                color: licColor,
                                size: 13,
                              ),
                            ],
                          ),
                          collapsedLabel: null,
                          expandedLabel: isLicValid
                              ? tr('lic_valid')
                              : tr('lic_invalid'),
                          textColor: licColor,
                          tooltip: isLicValid
                              ? '${tr('lic_valid')} (${_licenseInfo!.daysRemaining} ${tr('lic_days_left').replaceAll('{days}', '')})'
                              : tr('lic_invalid'),
                          colors: c,
                          onTap: _openLicenseManager,
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                  ],

                  // 2. Quick Performance Tier Switcher (⚡ Auto / Ultra / Balanced / Lite - Showcase Style)
                  TopBarExpandingButton(
                    icon: Icon(
                      t.effectiveTier.icon,
                      color: t.effectiveTier.color,
                      size: 14,
                    ),
                    collapsedLabel: null,
                    expandedLabel: '⚡ ${t.perfLabel}',
                    textColor: t.effectiveTier.color,
                    tooltip: tr('perf_tooltip'),
                    colors: c,
                    onTap: _cyclePerfTier,
                  ),
                  const SizedBox(width: 6),

                  // 3. Settings Button with Hover Expand (Showcase Style)
                  TopBarExpandingButton(
                    icon: Icon(
                      Icons.settings_rounded,
                      color: c.accentCyan,
                      size: 14,
                    ),
                    collapsedLabel: null,
                    expandedLabel: tr('settings_btn_label'),
                    textColor: c.accentCyan,
                    tooltip: tr('settings_tooltip'),
                    colors: c,
                    onTap: () => _openSettings(),
                  ),
                  const SizedBox(width: 6),

                  // 3. Quick Language Switcher with Hover Expand (Showcase Style)
                  Builder(
                    builder: (context) {
                      final lang = getLang();
                      final String langName;
                      switch (lang) {
                        case 'EN':
                          langName = 'English';
                          break;
                        case 'CN':
                          langName = '中文';
                          break;
                        case 'VI':
                        default:
                          langName = 'Tiếng Việt';
                          break;
                      }
                      return TopBarExpandingButton(
                        icon: Icon(
                          Icons.translate_rounded,
                          size: 14,
                          color: c.accentCyan,
                        ),
                        collapsedLabel: lang,
                        expandedLabel: langName,
                        textColor: c.accentCyan,
                        tooltip: tr(
                          'tooltip_change_lang',
                        ).replaceAll('{lang}', lang),
                        colors: c,
                        onTap: _cycleLanguage,
                      );
                    },
                  ),
                  const SizedBox(width: 6),

                  // 4. Theme Toggle Button with Hover Expand (Showcase Style)
                  TopBarExpandingButton(
                    icon: Icon(
                      t.isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: t.isDark ? c.accentAmber : c.accentPurple,
                      size: 14,
                    ),
                    collapsedLabel: null,
                    expandedLabel: t.isDark
                        ? tr('theme_light')
                        : tr('theme_dark'),
                    textColor: t.isDark ? c.accentAmber : c.accentPurple,
                    tooltip: t.isDark
                        ? tr('tooltip_theme_light')
                        : tr('tooltip_theme_dark'),
                    colors: c,
                    onTap: _toggleTheme,
                  ),
                ],
              ),
            ),

            // ══════════════════════════════════════════════════════════════════
            //  2. SMART BENTO FIRMWARE PROFILE SELECTOR (3 SLOTS)
            // ══════════════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.headerBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3 Interactive Slot Bento Cards
                  Row(
                    children: List.generate(3, (index) {
                      final slot = _slots[index];
                      final isSelected = _activeFwSlot == index;
                      final slotColor = slot.type.color;
                      final validation = slot.lastValidation;

                      // Adaptive Slot Card & Badge Styling
                      final Color? cardBg = isSelected
                          ? (c.isDark
                              ? Color.alphaBlend(
                                  slotColor.withValues(alpha: 0.18),
                                  const Color(0xFF1E293B).withValues(
                                    alpha: (t.cardOpacity * 1.5).clamp(0.20, 0.90),
                                  ),
                                )
                              : Color.alphaBlend(
                                  slotColor.withValues(alpha: 0.08),
                                  Colors.white.withValues(
                                    alpha: (t.cardOpacity * 2.2).clamp(0.40, 0.96),
                                  ),
                                ))
                          : (c.isDark
                              ? null
                              : Colors.white.withValues(
                                  alpha: (t.cardOpacity * 2.0).clamp(0.20, 0.90),
                                ));

                      final Color badgeTextColor = c.isDark
                          ? slotColor
                          : (slot.type == FirmwareSlotType.factory
                              ? const Color(0xFF0369A1) // Sky 700
                              : (slot.type == FirmwareSlotType.user
                                  ? const Color(0xFF047857) // Emerald 700
                                  : const Color(0xFFB45309))); // Amber 700

                      final Color badgeBg = c.isDark
                          ? slotColor.withValues(
                              alpha: isSelected ? 0.28 : 0.12,
                            )
                          : (slot.type == FirmwareSlotType.factory
                              ? const Color(0xFFE0F2FE)
                              : (slot.type == FirmwareSlotType.user
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEF3C7)))
                              .withValues(alpha: isSelected ? 0.95 : 0.75);

                      final Color badgeBorder = c.isDark
                          ? slotColor.withValues(
                              alpha: isSelected ? 0.70 : 0.30,
                            )
                          : (slot.type == FirmwareSlotType.factory
                              ? const Color(0xFFBAE6FD)
                              : (slot.type == FirmwareSlotType.user
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A)));

                      final Color errorStatusColor = c.isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFE11D48);

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < 2 ? 8.0 : 0.0,
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isSelected ? 1.0 : 0.92,
                            child: RotatingGlowBorder(
                              isActive: isSelected,
                              color: slotColor,
                              borderRadius: 16.0,
                              borderWidth: 2.0,
                              glowBlur: 6.0,
                              duration: const Duration(milliseconds: 3000),
                              child: BentoCard(
                                colors: c,
                                blurSigma: t.cardBlur,
                                bgOpacity: isSelected
                                    ? (t.cardOpacity * 1.3).clamp(0.10, 0.95)
                                    : t.cardOpacity,
                                isFeatured: isSelected,
                                showTopHighlight: !isSelected,
                                customBg: cardBg,
                                customBorder: isSelected
                                    ? (c.isDark
                                        ? slotColor.withValues(alpha: 0.35)
                                        : slotColor.withValues(alpha: 0.55))
                                    : null,
                                glowColor: isSelected
                                    ? (c.isDark ? slotColor : null)
                                    : null,
                                borderWidth: isSelected ? 2.0 : 1.0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                onTap: () => _switchFwSlot(index),
                                onDoubleTap: () => _renameSlot(index),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Slot Type Badge
                                        PillBadge(
                                          label:
                                              '${tr('slot_indicator_prefix')} ${index + 1} • ${slot.type.localizedBadge}',
                                          icon: slot.type.icon,
                                          color: badgeTextColor,
                                          bg: badgeBg,
                                          border: badgeBorder,
                                          fontSize: 9.0,
                                        ),
                                        const Spacer(),
                                        // Active Selected Tag
                                        if (isSelected) ...[
                                          PillBadge(
                                            label: tr('slot_active_badge'),
                                            icon: Icons.check_circle_rounded,
                                            color: badgeTextColor,
                                            bg: badgeBg,
                                            border: badgeBorder,
                                            fontSize: 8.5,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        // Rename Button on Slot Card Header
                                        Tooltip(
                                          message: tr('tooltip_rename_slot')
                                              .replaceAll(
                                                '{slot}',
                                                '${index + 1}',
                                              ),
                                          child: InkWell(
                                            onTap: () => _renameSlot(index),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                2.0,
                                              ),
                                              child: Icon(
                                                Icons
                                                    .drive_file_rename_outline_rounded,
                                                size: 14,
                                                color: isSelected
                                                    ? badgeTextColor
                                                    : c.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),

                                    // Slot Name
                                    Text(
                                      slot.displayName,
                                      style: TextStyle(
                                        color: c.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),

                                    // Validation state summary
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: validation.isValid
                                                ? c.accentEmerald
                                                : (validation.statusKey ==
                                                          'fw_missing'
                                                      ? c.accentAmber
                                                      : errorStatusColor),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            validation.isValid
                                                ? tr('fw_ready').replaceAll(
                                                    '{fh}',
                                                    validation
                                                            .detectedFirehose ??
                                                        '',
                                                  )
                                                : validation.localizedMessage,
                                            style: TextStyle(
                                              color: validation.isValid
                                                  ? c.accentEmerald
                                                  : (validation.statusKey ==
                                                            'fw_missing'
                                                        ? c.accentAmber
                                                        : errorStatusColor),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),

                  // Active Slot Detail & Folder Operations Bar
                  SubCard(
                    colors: c,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          activeSlot.type.icon,
                          size: 15,
                          color: activeSlot.type.color,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tr(
                            'slot_path_label',
                          ).replaceAll('{slot}', '${_activeFwSlot + 1}'),
                          style: TextStyle(
                            color: c.textPrimary.withValues(alpha: 0.92),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Editable & Pasteable Monospaced Path Input with Bounce Marquee
                        Expanded(
                          child: GlassBouncePathField(
                            controller: _pathController,
                            colors: c,
                            hintText: tr('hint_paste_or_browse'),
                            onSubmitted: (val) => _updateActiveSlotPath(val),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Quick 1-Click Paste Button
                        OutlinedButton.icon(
                          onPressed: _pastePathFromClipboard,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.accentCyan,
                            side: BorderSide(
                              color: c.accentCyan.withValues(alpha: 0.45),
                            ),
                            backgroundColor: c.accentCyan.withValues(
                              alpha: 0.08,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 12,
                          ),
                          label: Text(
                            tr('paste_btn'),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        // Browse Button (Modern Windows Explorer Dialog)
                        ElevatedButton.icon(
                          onPressed: _selectFirmwareFolder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.folder_open_rounded, size: 13),
                          label: Text(
                            tr('change_btn'),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        // Reveal in Explorer Button
                        OutlinedButton.icon(
                          onPressed: _revealActiveFolder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textPrimary,
                            side: BorderSide(color: c.borderDefault),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 12),
                          label: Text(
                            tr('open_folder_btn'),
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ),
                        const SizedBox(width: 5),

                        // Rename Slot Label Button
                        GlassIconButton(
                          icon: Icons.edit_note_rounded,
                          tooltip: tr('rename_slot'),
                          colors: c,
                          size: 28,
                          onPressed: _renameActiveSlot,
                        ),
                        const SizedBox(width: 8),

                        // Validation Status Badge
                        PillBadge(
                          label: fwStatusText,
                          color: fwStatusColor,
                          bg: fwStatusColor.withValues(alpha: 0.12),
                          border: fwStatusColor.withValues(alpha: 0.35),
                          showDot: activeValidation.isValid,
                          fontSize: 9.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ══════════════════════════════════════════════════════════════════
            //  3. BENTO ACTION TOOLBAR
            // ══════════════════════════════════════════════════════════════════
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.headerBorder)),
              ),
              child: SizedBox(
                height: 30,
                child: Row(
                  children: [
                    // Scan Devices Button (Slim)
                    SizedBox(
                      height: 28,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _deviceManager.poll();
                          _appendGlobalLog(
                            'Đang thực hiện quét thiết bị thủ công…',
                            'info',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(color: c.borderDefault),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: c.accentCyan,
                        ),
                        label: Text(
                          tr('scan_now'),
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Auto Flash Switch with Glowing Status (Slim)
                    Tooltip(
                      message: tr('auto_flash_tip'),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          color: _autoFlash
                              ? c.accentCyan.withValues(alpha: 0.12)
                              : c.subCardBg,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: _autoFlash
                                ? c.accentCyan.withValues(alpha: 0.4)
                                : c.subCardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: _autoFlash ? c.accentCyan : c.textMuted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tr('auto_flash_label'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _autoFlash
                                    ? c.accentCyan
                                    : c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 18,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Switch(
                                  value: _autoFlash,
                                  activeTrackColor: c.accentCyan,
                                  activeThumbColor: Colors.white,
                                  inactiveThumbColor: c.textMuted,
                                  inactiveTrackColor: c.subCardBg,
                                  onChanged: (val) {
                                    setState(() {
                                      _autoFlash = val;
                                      if (val) {
                                        _flashCycled.clear();
                                        _autoProcessed.clear();
                                        for (final port in _sessions.keys) {
                                          _startFlash(port);
                                        }
                                        _runAutoPipeline();
                                      }
                                    });
                                    _appendGlobalLog(
                                      val
                                          ? tr('auto_on_status')
                                          : tr('auto_off_status'),
                                      'info',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Live Counters: EDL & ADB/Fastboot
                    PillBadge(
                      label: 'EDL: ${_sessions.length}',
                      color: c.accentCyan,
                      bg: c.accentCyan.withValues(alpha: 0.12),
                      border: c.accentCyan.withValues(alpha: 0.3),
                      showDot: _sessions.isNotEmpty,
                      fontSize: 9.5,
                    ),
                    const SizedBox(width: 6),
                    PillBadge(
                      label: 'ADB: ${_deviceManager.knownAdb.length}',
                      color: c.accentPurple,
                      bg: c.accentPurple.withValues(alpha: 0.12),
                      border: c.accentPurple.withValues(alpha: 0.3),
                      showDot: _deviceManager.knownAdb.isNotEmpty,
                      fontSize: 9.5,
                    ),

                    const Spacer(),

                    // Flash All Action Button (Glowing Cyan Gradient, Slim 28px)
                    GlowingActionButton(
                      height: 28,
                      label: tr('flash_all'),
                      icon: Icons.flash_on_rounded,
                      colors: c,
                      customStartColor: c.accentColor,
                      customEndColor: c.accentCyan,
                      onPressed: _sessions.isEmpty ? null : _startFlashAll,
                    ),
                    const SizedBox(width: 8),

                    // Stop All Action Button (Glowing Rose Red, Slim 28px)
                    GlowingActionButton(
                      height: 28,
                      label: tr('abort_all'),
                      icon: Icons.stop_circle_rounded,
                      colors: c,
                      isDestructive: true,
                      onPressed:
                          _sessions.isEmpty &&
                              _fastbootWorkers.isEmpty &&
                              _rebootWorkers.isEmpty
                          ? null
                          : _abortAll,
                    ),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════════════════════════
            //  4. TWO-COLUMN DEVICE PANELS (EDL & ADB/FASTBOOT)
            // ══════════════════════════════════════════════════════════════════
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ──────────────────────────────────────────────────────────
                    //  COLUMN 1: EDL (9008) DEVICES
                    // ──────────────────────────────────────────────────────────
                    Expanded(
                      flex: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.headerBg.withValues(
                            alpha: (t.cardOpacity * 1.4).clamp(0.15, 0.70),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.headerBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // EDL Column Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: c.subCardBg.withValues(
                                  alpha: (t.cardOpacity * 1.6).clamp(0.20, 0.85),
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(9),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: c.headerBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: c.accentCyan.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: c.accentCyan.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.memory_rounded,
                                      color: c.accentCyan,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('edl_header'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PillBadge(
                                    label: '${_sessions.length}',
                                    color: c.accentCyan,
                                    bg: c.accentCyan.withValues(alpha: 0.15),
                                    border: c.accentCyan.withValues(
                                      alpha: 0.35,
                                    ),
                                    fontSize: 9.5,
                                  ),
                                  const Spacer(),
                                  Tooltip(
                                    message: tr('reboot_all_tip'),
                                    child: InkWell(
                                      onTap: _sessions.isEmpty
                                          ? null
                                          : () {
                                              for (final port
                                                  in _sessions.keys) {
                                                _runRebootWorker(port);
                                              }
                                            },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.replay_rounded,
                                              size: 13,
                                              color: _sessions.isEmpty
                                                  ? c.textMuted
                                                  : c.accentAmber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tr('reboot_all_adb'),
                                              style: TextStyle(
                                                color: _sessions.isEmpty
                                                    ? c.textMuted
                                                    : c.accentAmber,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // EDL Devices Body (Scrollable Grid or Placeholder)
                            Expanded(
                              child: _sessions.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.usb_rounded,
                                              size: 32,
                                              color: c.textSecondary.withValues(
                                                alpha: 0.55,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              tr('placeholder_edl'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: c.textSecondary
                                                    .withValues(alpha: 0.90),
                                                fontSize: 11.5,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(8),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _sessions.entries.map((
                                          entry,
                                        ) {
                                          return DeviceCard(
                                            session: entry.value,
                                            theme: t,
                                            autoFlashLocked: _autoFlash,
                                            onFlashRequested: _startFlash,
                                            onAbortRequested: _abortFlash,
                                            onRebootRequested: _runRebootWorker,
                                            onRemoveRequested: (port) {
                                              setState(() {
                                                _sessions.remove(port);
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // ──────────────────────────────────────────────────────────
                    //  COLUMN 2: ADB / FASTBOOT DEVICES
                    // ──────────────────────────────────────────────────────────
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.headerBg.withValues(
                            alpha: (t.cardOpacity * 1.4).clamp(0.15, 0.70),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.headerBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ADB Column Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: c.subCardBg.withValues(
                                  alpha: (t.cardOpacity * 1.6).clamp(0.20, 0.85),
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(9),
                                ),
                                border: Border(
                                  bottom: BorderSide(color: c.headerBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: c.accentPurple.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: c.accentPurple.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.phone_android_rounded,
                                      color: c.accentPurple,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('adb_header'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PillBadge(
                                    label: '${_deviceManager.knownAdb.length}',
                                    color: c.accentPurple,
                                    bg: c.accentPurple.withValues(alpha: 0.15),
                                    border: c.accentPurple.withValues(
                                      alpha: 0.35,
                                    ),
                                    fontSize: 9.5,
                                  ),
                                  const Spacer(),
                                  Tooltip(
                                    message: tr('boot_all_tip'),
                                    child: InkWell(
                                      onTap: _deviceManager.knownAdb.isEmpty
                                          ? null
                                          : () {
                                              for (final dev
                                                  in _deviceManager.knownAdb) {
                                                if (dev.isFastboot) {
                                                  _runFastbootToEdlWorker(
                                                    dev.serial,
                                                  );
                                                } else {
                                                  _triggerAdbRebootEdl(
                                                    dev.serial,
                                                  );
                                                }
                                              }
                                            },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.restart_alt_rounded,
                                              size: 13,
                                              color:
                                                  _deviceManager
                                                      .knownAdb
                                                      .isEmpty
                                                  ? c.textMuted
                                                  : c.accentPurple,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              tr('boot_all_edl'),
                                              style: TextStyle(
                                                color:
                                                    _deviceManager
                                                        .knownAdb
                                                        .isEmpty
                                                    ? c.textMuted
                                                    : c.accentPurple,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ADB Devices Body (Scrollable Grid or Placeholder)
                            Expanded(
                              child: _deviceManager.knownAdb.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.phone_android_rounded,
                                              size: 28,
                                              color: c.textSecondary.withValues(
                                                alpha: 0.55,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              tr('placeholder_adb'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: c.textSecondary
                                                    .withValues(alpha: 0.90),
                                                fontSize: 11.5,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(8),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _deviceManager.knownAdb.map((
                                          dev,
                                        ) {
                                          final status =
                                              _adbStatus[dev.serial] ?? 'idle';
                                          return AdbDeviceCard(
                                            device: dev,
                                            theme: t,
                                            status: status,
                                            autoFlashLocked: _autoFlash,
                                            onRemoveRequested: (serial) {
                                              setState(() {
                                                _deviceManager.knownAdb
                                                    .removeWhere(
                                                      (d) => d.serial == serial,
                                                    );
                                              });
                                            },
                                            onBootRequested:
                                                (serial, isFastboot) {
                                                  if (isFastboot) {
                                                    _runFastbootToEdlWorker(
                                                      serial,
                                                    );
                                                  } else {
                                                    _triggerAdbRebootEdl(
                                                      serial,
                                                    );
                                                  }
                                                },
                                          );
                                        }).toList(),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ══════════════════════════════════════════════════════════════════
            //  5. TERMINAL LOG MONITOR (COLLAPSIBLE BENTO CONSOLE)
            // ══════════════════════════════════════════════════════════════════
            RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              height: _terminalHeightMode == 0
                  ? 34.0
                  : (_terminalHeightMode == 1 ? 95.0 : 180.0),
              decoration: BoxDecoration(
                color: c.headerBg,
                border: Border(top: BorderSide(color: c.headerBorder)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 14,
                        color: c.accentCyan,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr('terminal_title'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PillBadge(
                        label: '${_globalLogs.length} ${tr('log_lines_count')}',
                        color: c.textSecondary,
                        bg: c.subCardBg,
                        border: c.subCardBorder,
                        fontSize: 8.5,
                      ),
                      const SizedBox(width: 6),
                      PillBadge(
                        label: _terminalHeightMode == 0
                            ? tr('terminal_height_collapsed')
                            : (_terminalHeightMode == 1
                                  ? tr('terminal_height_compact')
                                  : tr('terminal_height_expanded')),
                        color: c.accentCyan,
                        bg: c.accentCyan.withValues(alpha: 0.12),
                        border: c.accentCyan.withValues(alpha: 0.3),
                        fontSize: 8.5,
                      ),
                      const Spacer(),

                      // Toggle Height Mode Button
                      Tooltip(
                        message: tr('terminal_toggle_tooltip'),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _terminalHeightMode =
                                  (_terminalHeightMode + 1) % 3;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _terminalHeightMode == 0
                                      ? Icons.keyboard_arrow_up_rounded
                                      : (_terminalHeightMode == 1
                                            ? Icons.unfold_more_rounded
                                            : Icons
                                                  .keyboard_arrow_down_rounded),
                                  size: 14,
                                  color: c.accentCyan,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _terminalHeightMode == 0
                                      ? tr('terminal_height_collapsed')
                                      : (_terminalHeightMode == 1
                                            ? tr('terminal_height_compact')
                                            : tr('terminal_height_expanded')),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: c.accentCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Copy Logs Button
                      InkWell(
                        onTap: _copyAllLogs,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.content_copy_rounded,
                                size: 12,
                                color: c.accentCyan,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                tr('copy_logs'),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: c.accentCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Clear Logs Button
                      InkWell(
                        onTap: _clearLogs,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 12,
                                color: c.accentRose,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                tr('clear_logs'),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: c.accentRose,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_terminalHeightMode != 0) ...[
                    const SizedBox(height: 4),

                    // Log ListView
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.subCardBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.subCardBorder),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ListView.builder(
                          controller: _globalLogController,
                          itemCount: _globalLogs.length,
                          itemBuilder: (context, index) {
                            final logLine = _globalLogs[index];
                            Color logColor = c.textSecondary;
                            if (logLine.contains('[SUCCESS]')) {
                              logColor = c.isDark ? const Color(0xFF6EE7B7) : c.accentEmerald;
                            } else if (logLine.contains('[ERROR]')) {
                              logColor = c.isDark ? const Color(0xFFFCA5A5) : c.accentRose;
                            } else if (logLine.contains('[WARN]')) {
                              logColor = c.isDark ? const Color(0xFFFDE047) : c.accentAmber;
                            } else if (logLine.contains('[INFO]')) {
                              logColor = c.isDark ? const Color(0xFF67E8F9) : c.accentCyan;
                            }
                            return Text(
                              logLine,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10.0,
                                color: logColor,
                                height: 1.3,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
