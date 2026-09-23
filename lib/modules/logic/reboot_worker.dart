// lib/modules/logic/reboot_worker.dart
import 'dart:isolate';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../constants.dart';
import '../i18n.dart';
import 'operation_support.dart';
import 'flash_isolate.dart';
import 'sahara.dart';

class RebootWorker {
  final String port;
  final String fwDir;
  ManagedProcess? _process;
  SaharaIsolateHandle? _sahara;
  bool resetting = false;
  bool _aborted = false;

  RebootWorker({required this.port, required this.fwDir});

  void abort() {
    _aborted = true;
    _process?.abort();
    _sahara?.abort();
  }

  /// Run the reboot sequence.
  Future<(bool, String)> run({
    void Function(String msg, String level)? onLog,
  }) async {
    return DeviceOperationQueue.shared.run(() async {
      if (_aborted) return (false, 'Aborted');
      try {
        return await withQualcommService(() => _run(onLog: onLog));
      } catch (error) {
        return (false, 'Reboot failed: $error');
      }
    });
  }

  Future<(bool, String)> _run({void Function(String, String)? onLog}) async {
    if (_aborted) return (false, 'Aborted');
    final logsDir = Directory(p.join(baseDir, 'logs'));
    if (!logsDir.existsSync()) logsDir.createSync(recursive: true);

    void log(String msg, [String level = 'info']) {
      if (onLog != null) {
        onLog('[$port] $msg', level);
      }
    }

    final elfPath = p.join(fwDir, firehoseElf);

    // ══════════════════════════════════════════════════════════════════
    //  Path A — Firehose-based reboot (PROPER approach)
    // ══════════════════════════════════════════════════════════════════
    log(tr('log_reboot_path_a'));

    if (!File(elfPath).existsSync()) {
      log(tr('log_reboot_elf_missing').replaceAll('{path}', elfPath), 'warn');
      return await _pathB(log);
    }

    if (!File(fhLoaderExePath).existsSync()) {
      log(tr('log_reboot_fh_missing'), 'warn');
      return await _pathB(log);
    }

    if (_aborted) return (false, 'Aborted');

    // Upload firehose programmer
    final (saharaOk, saharaMsg) = await (_sahara = SaharaIsolateHandle()).run(
      port: port,
      elfPath: elfPath,
      onLog: (m, l) => log('  [Sahara] $m', l),
    );

    if (_aborted) return (false, 'Aborted');

    if (!saharaOk) {
      log(
        '[Path A] Nạp driver Sahara thất bại: $saharaMsg — chuyển sang Sahara RESET',
        'warn',
      );
      return await _pathB(log);
    }

    log(tr('log_reboot_driver_ok'), 'success');
    await Future.delayed(const Duration(seconds: 2));
    if (_aborted) return (false, 'Aborted');

    final portTracePath = p.join(
      logsDir.path,
      'reboot_trace_${port}_${DateTime.now().microsecondsSinceEpoch}.txt',
    );
    final fwAbs = Directory(fwDir).absolute.path;
    final args = [
      '--port=\\\\.\\$port',
      '--search_path=$fwAbs',
      '--noprompt',
      '--showpercentagecomplete',
      '--zlpawarehost=1',
      '--memoryname=emmc',
      '--setactivepartition=0',
      '--reset',
      '--porttracename=$portTracePath',
    ];

    try {
      resetting = true;
      final process = ManagedProcess();
      _process = process;
      final exitCode = await process.run(
        fhLoaderExePath,
        args,
        workingDirectory: fwAbs,
        idleTimeout: const Duration(minutes: 2),
        totalTimeout: const Duration(minutes: 5),
        onLine: (line, isError) =>
            log('  [fh] $line', isError ? 'error' : 'info'),
      );
      _process = null;
      if (_aborted) return (false, 'Aborted');

      if (exitCode == 0) {
        return (
          true,
          tr('log_reboot_firehose_success').replaceAll('{port}', port),
        );
      }
    } catch (e) {
      log(tr('log_reboot_fh_error').replaceAll('{err}', e.toString()), 'error');
    }

    if (_aborted) return (false, 'Aborted');

    log(tr('log_reboot_fh_fail_fallback'), 'warn');
    return await _pathB(log);
  }

  /// Path B: raw Sahara RESET (fallback)
  Future<(bool, String)> _pathB(
    void Function(String msg, String level) log,
  ) async {
    if (_aborted) return (false, 'Aborted');
    log(tr('log_reboot_path_b'), 'warn');
    resetting = true;
    final targetPort = port;
    final (ok, msg) = await Isolate.run(
      () => saharaResetPort(targetPort, manageService: false),
    );
    if (_aborted) return (false, 'Aborted');
    if (ok) {
      log(tr('log_reboot_reset_ok'), 'success');
      return (true, tr('log_reboot_sahara_success').replaceAll('{port}', port));
    } else {
      log(tr('log_reboot_reset_fail').replaceAll('{msg}', msg), 'error');
      return (
        false,
        tr(
          'log_reboot_both_failed',
        ).replaceAll('{port}', port).replaceAll('{msg}', msg),
      );
    }
  }
}
