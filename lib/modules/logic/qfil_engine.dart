// lib/modules/logic/qfil_engine.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../i18n.dart';
import '../utils.dart';
import 'flash_isolate.dart';

final RegExp _rePercentFh = RegExp(
  r'\{percent files transferred\s+([\d\.]+)\%\}',
);
final RegExp _rePercentAlt = RegExp(r'(\d{1,3}(?:\.\d+)?)\s*\%');
final RegExp _reOk = RegExp(r'\bsucc(?:ess|eeded)\b', caseSensitive: false);
final RegExp _reError = RegExp(
  r'\b(?:error|fail(?:ed)?|abort)\b',
  caseSensitive: false,
);

class QfilEngine {
  final String port;
  final String fwDir;
  final bool autoReboot;

  // Sahara Hello properties
  final bool helloCaptured;
  final int helloVersion;
  final int helloVersionSup;
  final int helloMode;

  Process? _process;
  SaharaIsolateHandle? _saharaHandle;
  bool _aborted = false;

  QfilEngine({
    required this.port,
    required this.fwDir,
    this.autoReboot = true,
    this.helloCaptured = false,
    this.helloVersion = 2,
    this.helloVersionSup = 1,
    this.helloMode = 0,
  });

  /// Aborts the running flash operation by killing the subprocess and sahara isolate.
  void abort() {
    _aborted = true;
    _saharaHandle?.abort();
    _process?.kill();
  }

  /// Execute the 2-phase flashing sequence. Returns true on success.
  Future<bool> run({
    void Function(int percentage)? onProgress,
    void Function(String message, String level)? onLog,
    void Function(bool success, String summary)? onDone,
  }) async {
    _aborted = false;
    final fwAbs = Directory(fwDir).absolute.path;

    void log(String msg, [String level = 'info']) {
      if (onLog != null) {
        onLog('[$port] $msg', level);
      }
    }

    // ── Validation ──────────────────────────────────────────────────────────
    if (!File(fhLoaderExePath).existsSync()) {
      return _fail(
        tr('err_fh_loader_missing').replaceAll('{path}', fhLoaderExePath),
        onLog,
        onDone,
      );
    }

    final reqFiles = [rawprogramXml, patchXml, firehoseElf];
    for (final req in reqFiles) {
      final fPath = p.join(fwAbs, req);
      if (!File(fPath).existsSync()) {
        return _fail(
          tr('err_fw_file_missing').replaceAll('{file}', req),
          onLog,
          onDone,
        );
      }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  PHASE 1 — Sahara programmer upload
    // ══════════════════════════════════════════════════════════════════════
    final elfPath = p.join(fwAbs, firehoseElf);
    log('━' * 48);
    log('[PHASE 1] Sahara upload → $firehoseElf');

    bool svcStopped = false;
    if (!helloCaptured) {
      log(tr('log_stopping_mtu_service'));
      svcStopped = await stopQualcommService();
      if (svcStopped) {
        log(tr('log_mtu_service_stopped'), 'success');
      } else {
        log(tr('log_mtu_service_stop_fail'), 'warn');
      }
    }

    if (onProgress != null) onProgress(2);

    if (_aborted) {
      if (svcStopped) await startQualcommService();
      return _abortedResult(onLog, onDone);
    }

    // Run in a separate isolate so Win32 ReadFile() doesn't block the UI thread
    _saharaHandle = SaharaIsolateHandle();
    final (saharaOk, saharaMsg) = await _saharaHandle!.run(
      port: port,
      elfPath: elfPath,
      helloCaptured: helloCaptured,
      helloVersion: helloVersion,
      helloVersionSup: helloVersionSup,
      helloMode: helloMode,
      onLog: (m, l) => log('  [Sahara] $m', l),
      onProgress: (pct) {
        // Map 0-100% of Sahara upload -> 2-8% of total progress
        final mapped = 2 + (pct * 0.06).toInt();
        if (onProgress != null) onProgress(mapped);
      },
    );
    _saharaHandle = null;

    if (_aborted) {
      if (svcStopped) await startQualcommService();
      return _abortedResult(onLog, onDone);
    }

    if (!saharaOk) {
      if (svcStopped) await startQualcommService();
      return _fail(
        tr('err_sahara_upload_fail').replaceAll('{msg}', saharaMsg),
        onLog,
        onDone,
      );
    }

    log(
      tr('log_sahara_upload_success').replaceAll('{msg}', saharaMsg),
      'success',
    );
    log(tr('log_wait_firehose'));
    if (onProgress != null) onProgress(8);
    await Future.delayed(const Duration(seconds: 2));

    // Restart service since Sahara is done
    if (svcStopped) {
      await startQualcommService();
      svcStopped = false;
    }

    if (_aborted) return _abortedResult(onLog, onDone);

    // ══════════════════════════════════════════════════════════════════════
    //  PHASE 2 — Firehose: flash partitions via fh_loader.exe
    // ══════════════════════════════════════════════════════════════════════
    final logsDir = Directory(p.join(baseDir, 'logs'));
    if (!logsDir.existsSync()) logsDir.createSync(recursive: true);
    final portTracePath = p.join(logsDir.path, 'port_trace_$port.txt');

    final commonArgs = [
      '--port=\\\\.\\$port',
      '--search_path=$fwAbs',
      '--noprompt',
      '--showpercentagecomplete',
      '--zlpawarehost=1',
      '--memoryname=emmc',
    ];

    // Call 1: send XML rawprogram + patch
    final flashArgs = [
      ...commonArgs,
      '--sendxml=$rawprogramXml',
      '--sendxml=$patchXml',
      '--porttracename=$portTracePath',
    ];

    log('━' * 48);
    log(tr('log_phase2_start').replaceAll('{port}', port));
    log(
      tr(
        'log_phase2_command',
      ).replaceAll('{port}', port).replaceAll('{path}', fwAbs),
    );

    final flashSuccess = await _runFhLoader(
      args: flashArgs,
      workDir: fwAbs,
      label: 'PHASE 2',
      pctLo: 8,
      pctHi: 94,
      onProgress: onProgress,
      onLog: log,
    );

    if (_aborted) return _abortedResult(onLog, onDone);
    if (!flashSuccess) {
      return _fail(tr('err_flash_failed'), onLog, onDone);
    }

    if (onProgress != null) onProgress(95);

    // ══════════════════════════════════════════════════════════════════════
    //  PHASE 2b — Set active partition and reset
    // ══════════════════════════════════════════════════════════════════════
    log('━' * 48);
    log(tr('log_phase2b_start'));

    final activeArgs = [...commonArgs, '--setactivepartition=0'];
    if (autoReboot) {
      activeArgs.add('--reset');
    }

    final activeSuccess = await _runFhLoader(
      args: activeArgs,
      workDir: fwAbs,
      label: 'PHASE 2b',
      pctLo: 95,
      pctHi: 99,
      onProgress: onProgress,
      onLog: log,
    );

    if (_aborted) return _abortedResult(onLog, onDone);

    final success = flashSuccess && activeSuccess;
    final summary = success
        ? tr('log_flash_complete')
        : tr('err_active_slot_fail');
    final level = success ? 'success' : 'error';

    log(summary, level);

    if (success && onProgress != null) onProgress(100);
    if (onDone != null) onDone(success, summary);

    return success;
  }

  /// Run one instance of fh_loader process and stream parse its stdout
  Future<bool> _runFhLoader({
    required List<String> args,
    required String workDir,
    required String label,
    required int pctLo,
    required int pctHi,
    required void Function(int pct)? onProgress,
    required void Function(String msg, String lvl) onLog,
  }) async {
    if (_aborted) return false;
    try {
      _process = await Process.start(
        fhLoaderExePath,
        args,
        workingDirectory: workDir,
      );
      if (_aborted) _process!.kill();
    } catch (e) {
      onLog(
        '[$label] ${tr('err_fh_loader_start').replaceAll('{err}', '$e')}',
        'error',
      );
      return false;
    }

    final process = _process!;
    final stderrDone = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach((line) {
          if (!_aborted && line.trim().isNotEmpty) onLog(line, 'error');
        });
    int lastPct = -1;

    // Listen to stdout stream
    final stdoutStream = _process!.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());

    await for (var line in stdoutStream) {
      if (_aborted) break;
      line = line.trim();
      if (line.isEmpty) continue;

      // Determine log levels
      String lvl = 'info';
      if (_reError.hasMatch(line)) {
        lvl = 'error';
      } else if (_reOk.hasMatch(line)) {
        lvl = 'success';
      }
      onLog(line, lvl);

      // Parse percentages
      if (onProgress != null) {
        double? pctVal;

        final m1 = _rePercentFh.firstMatch(line);
        if (m1 != null) {
          pctVal = double.tryParse(m1.group(1) ?? '');
        } else {
          // Fallback bare percent if line references transferred progress
          if (line.toLowerCase().contains('percent') ||
              line.toLowerCase().contains('transferred')) {
            final m2 = _rePercentAlt.firstMatch(line);
            if (m2 != null) {
              pctVal = double.tryParse(m2.group(1) ?? '');
            }
          }
        }

        if (pctVal != null) {
          // Map 0-100% of fh_loader -> [pctLo, pctHi]
          final mapped = pctLo + (pctVal / 100.0 * (pctHi - pctLo)).toInt();
          final finalPct = mapped.clamp(pctLo, pctHi);
          if (finalPct > lastPct) {
            lastPct = finalPct;
            onProgress(finalPct);
          }
        }
      }
    }

    final exitCode = await process.exitCode;
    await stderrDone;
    _process = null;

    return !_aborted && exitCode == 0;
  }

  bool _fail(
    String msg,
    void Function(String, String)? onLog,
    void Function(bool, String)? onDone,
  ) {
    if (onLog != null) onLog('❌ $msg', 'error');
    if (onDone != null) onDone(false, msg);
    return false;
  }

  bool _abortedResult(
    void Function(String, String)? onLog,
    void Function(bool, String)? onDone,
  ) {
    final msg = tr('log_flash_aborted');
    if (onLog != null) onLog('⬜ $msg', 'warn');
    if (onDone != null) onDone(false, msg);
    return false;
  }
}
