// lib/modules/logic/flash_isolate.dart
//
// Runs the blocking Sahara serial handshake (FFI/Win32 ReadFile) in a
// dedicated Dart Isolate so the Flutter UI thread never freezes.
//
// Isolates do NOT share memory, so we pass all parameters as plain data
// (strings, ints, booleans) and stream results back via SendPort messages.

import 'dart:async';
import 'dart:isolate';

import '../i18n.dart';
import 'sahara.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Message types
// ─────────────────────────────────────────────────────────────────────────────
class _SaharaMsg {
  static const int log = 0;
  static const int progress = 1;
  static const int done = 2;

  final int type;
  final dynamic data; // log → [String msg, String level]
  // progress → int
  // done → [bool ok, String message]
  const _SaharaMsg(this.type, this.data);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Parameters passed into the Isolate (must be simple data)
// ─────────────────────────────────────────────────────────────────────────────
class _SaharaParams {
  final SendPort sendPort;
  final String port;
  final String elfPath;
  final bool helloCaptured;
  final int helloVersion;
  final int helloVersionSup;
  final int helloMode;
  final String lang;

  const _SaharaParams({
    required this.sendPort,
    required this.port,
    required this.elfPath,
    required this.helloCaptured,
    required this.helloVersion,
    required this.helloVersionSup,
    required this.helloMode,
    required this.lang,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Isolate entry point
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _saharaIsolateMain(_SaharaParams params) async {
  // Restore language context inside isolated memory space
  setLang(params.lang);

  final (ok, msg) = await saharaUploadProgrammer(
    port: params.port,
    elfPath: params.elfPath,
    helloCaptured: params.helloCaptured,
    helloVersion: params.helloVersion,
    helloVersionSup: params.helloVersionSup,
    helloMode: params.helloMode,
    onLog: (m, level) {
      params.sendPort.send(_SaharaMsg(_SaharaMsg.log, [m, level]));
    },
    onProgress: (pct) {
      params.sendPort.send(_SaharaMsg(_SaharaMsg.progress, pct));
    },
  );

  params.sendPort.send(_SaharaMsg(_SaharaMsg.done, [ok, msg]));
}

// ─────────────────────────────────────────────────────────────────────────────
//  Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Runs [saharaUploadProgrammer] in a background Dart Isolate.
/// Streams [onLog] and [onProgress] callbacks back to the caller.
/// Returns (success, message) when the isolate finishes.
///
/// The returned [IsolateHandle] can be used to abort mid-flight.
class SaharaIsolateHandle {
  Isolate? _isolate;
  bool _aborted = false;
  ReceivePort? _receivePort;
  Completer<(bool, String)>? _completion;

  Future<(bool, String)> run({
    required String port,
    required String elfPath,
    bool helloCaptured = false,
    int helloVersion = 2,
    int helloVersionSup = 1,
    int helloMode = 0,
    void Function(String msg, String level)? onLog,
    void Function(int pct)? onProgress,
  }) async {
    if (_completion != null) throw StateError('Sahara is already running');
    _aborted = false;

    final receivePort = ReceivePort();
    _receivePort = receivePort;
    final completer = Completer<(bool, String)>();
    _completion = completer;
    final params = _SaharaParams(
      sendPort: receivePort.sendPort,
      port: port,
      elfPath: elfPath,
      helloCaptured: helloCaptured,
      helloVersion: helloVersion,
      helloVersionSup: helloVersionSup,
      helloMode: helloMode,
      lang: getLang(),
    );

    receivePort.listen(
      (raw) {
        if (completer.isCompleted) return;
        if (raw == null || raw is List) {
          completer.complete((
            false,
            raw == null
                ? 'Sahara isolate exited without a result'
                : 'Sahara isolate error: ${raw.first}',
          ));
          return;
        }
        if (raw is! _SaharaMsg) return;
        switch (raw.type) {
          case _SaharaMsg.log:
            final parts = raw.data as List;
            onLog?.call(parts[0] as String, parts[1] as String);
          case _SaharaMsg.progress:
            onProgress?.call(raw.data as int);
          case _SaharaMsg.done:
            final parts = raw.data as List;
            receivePort.close();
            if (!completer.isCompleted) {
              completer.complete((parts[0] as bool, parts[1] as String));
            }
        }
      },
      onDone: () {
        // Port was closed (either by done message above, or by abort() killing the isolate)
        if (!completer.isCompleted) {
          completer.complete((false, tr('log_flash_aborted')));
        }
      },
    );

    try {
      _isolate = await Isolate.spawn(
        _saharaIsolateMain,
        params,
        onError: receivePort.sendPort,
        onExit: receivePort.sendPort,
        debugName: 'SaharaIsolate-$port',
      );
      if (_aborted) _isolate?.kill(priority: Isolate.immediate);
      return await completer.future;
    } catch (error) {
      return (false, 'Sahara isolate error: $error');
    } finally {
      receivePort.close();
      _receivePort = null;
      _isolate = null;
      _completion = null;
    }
  }

  /// Kill the isolate immediately (e.g. when user presses Abort).
  void abort() {
    if (!_aborted) {
      _aborted = true;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      final completion = _completion;
      if (completion != null && !completion.isCompleted) {
        completion.complete((false, tr('log_flash_aborted')));
      }
      _receivePort?.close();
    }
  }
}
