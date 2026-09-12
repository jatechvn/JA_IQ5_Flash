// lib/modules/logic/flash_session.dart
import 'package:flutter/foundation.dart';
import 'device_manager.dart';
import 'qfil_engine.dart';

class FlashSession extends ChangeNotifier {
  final DeviceInfo device;
  final String fwDir;
  final bool autoReboot;
  final QfilEngine Function(String firmwareDirectory)? engineFactory;

  static const String statusIdle = 'idle';
  static const String statusRunning = 'running';
  static const String statusSuccess = 'success';
  static const String statusError = 'error';
  static const String statusAborted = 'aborted';

  String _status = statusIdle;
  int _progress = 0;
  final List<String> logs = [];
  QfilEngine? _engine;
  bool _active = false;
  bool _disposed = false;

  // Global callbacks to notify MainWindow
  void Function(String port, int progress)? onProgressChanged;
  void Function(String port, String logLine, String level)? onLogMessage;
  void Function(String port, bool success, String summary)? onDone;

  FlashSession({
    required this.device,
    required this.fwDir,
    this.autoReboot = true,
    this.engineFactory,
    this.onProgressChanged,
    this.onLogMessage,
    this.onDone,
  });

  String get port => device.port;
  String get status => _status;
  int get progress => _progress;
  bool get isRunning => _active || _status == statusRunning;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _engine?.abort();
    onProgressChanged = null;
    onLogMessage = null;
    onDone = null;
    super.dispose();
  }

  /// Set session status.
  void setStatus(String newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  /// Append log to session.
  void appendLog(String message, [String level = 'info']) {
    logs.add(message);
    notifyListeners();
  }

  /// Aborts the running flash session.
  void abort() {
    if (!_active) return;
    _status = statusAborted;
    _engine?.abort();
    notifyListeners();
  }

  /// Start the flashing process.
  Future<bool> start({String? firmwareDirectory}) async {
    if (_disposed || isRunning) return false;
    _active = true;
    _status = statusRunning;
    _progress = 0;
    logs.clear();
    notifyListeners();

    var success = false;
    var summary = '';
    try {
      // Listeners may cancel or dispose synchronously when running is published.
      if (_disposed || _status == statusAborted) return false;
      _engine =
          engineFactory?.call(firmwareDirectory ?? fwDir) ??
          QfilEngine(
            port: port,
            fwDir: firmwareDirectory ?? fwDir,
            autoReboot: autoReboot,
            helloCaptured: device.saharaHelloOk,
            helloVersion: device.saharaVersion,
            helloVersionSup: device.saharaVersionSup,
            helloMode: device.saharaMode,
          );

      success = await _engine!.run(
        onProgress: (pct) {
          _progress = pct;
          notifyListeners();
          if (onProgressChanged != null) {
            onProgressChanged!(port, pct);
          }
        },
        onLog: (msg, lvl) {
          logs.add(msg);
          notifyListeners();
          if (onLogMessage != null) {
            onLogMessage!(port, msg, lvl);
          }
        },
        onDone: (ok, message) {
          // Publish completion only after the session status is finalized.
          summary = message;
        },
      );
    } catch (error) {
      summary = 'Flash error: $error';
      logs.add(summary);
      onLogMessage?.call(port, summary, 'error');
    } finally {
      _active = false;
      _engine = null;
    }
    if (_status == statusAborted || _disposed) success = false;
    if (_status != statusAborted) {
      _status = success ? statusSuccess : statusError;
    }
    notifyListeners();
    onDone?.call(port, success, summary);
    return success;
  }
}
