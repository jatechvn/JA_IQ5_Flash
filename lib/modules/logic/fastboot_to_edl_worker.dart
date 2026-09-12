// lib/modules/logic/fastboot_to_edl_worker.dart
import 'dart:io';
import '../constants.dart';
import '../i18n.dart';
import 'device_manager.dart';

const int adbWaitSeconds = 45;
const Duration pollInterval = Duration(milliseconds: 1500);

/// Send `adb -s <serial> reboot edl` command. Falls back to rebooting to bootloader.
typedef DeviceCommandRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

Future<(bool, String)> adbRebootEdl(
  String serial, {
  DeviceCommandRunner? commandRunner,
}) async {
  final runCommand =
      commandRunner ??
      (String executable, List<String> arguments) =>
          Process.run(executable, arguments);
  try {
    final res = await runCommand(adbExePath, ['-s', serial, 'reboot', 'edl']);
    if (res.exitCode == 0) {
      return (true, 'Lệnh reboot EDL đã gửi tới ADB: $serial');
    }

    // Fallback: reboot to bootloader
    final res2 = await runCommand(adbExePath, [
      '-s',
      serial,
      'reboot',
      'bootloader',
    ]);
    if (res2.exitCode == 0) {
      return (
        false,
        'Đã reboot sang Bootloader. Cần chạy fastboot oem edl tiếp theo.',
      );
    }
    return (false, 'Lỗi gửi lệnh reboot EDL: ${res.stderr} / ${res2.stderr}');
  } catch (e) {
    return (false, 'Lỗi kết nối ADB: $e');
  }
}

/// Send `fastboot -s <serial> oem edl` command. Falls back to reboot-edl.
Future<(bool, String)> fastbootRebootEdl(String serial) async {
  try {
    final res = await Process.run(fastbootExePath, [
      '-s',
      serial,
      'oem',
      'edl',
    ]);
    if (res.exitCode == 0) {
      return (true, 'Lệnh Fastboot OEM EDL đã gửi tới: $serial');
    }

    final res2 = await Process.run(fastbootExePath, [
      '-s',
      serial,
      'reboot-edl',
    ]);
    if (res2.exitCode == 0) {
      return (true, 'Lệnh Fastboot reboot-edl đã gửi tới: $serial');
    }
    return (false, 'Lỗi gửi lệnh Fastboot EDL: ${res.stderr} / ${res2.stderr}');
  } catch (e) {
    return (false, 'Lỗi Fastboot: $e');
  }
}

/// Reboot Fastboot device to System/ADB
Future<(bool, String)> fastbootRebootAdb(String serial) async {
  try {
    final res = await Process.run(fastbootExePath, ['-s', serial, 'reboot']);
    if (res.exitCode == 0) {
      return (true, 'Lệnh fastboot reboot gửi tới: $serial');
    }
    return (false, 'Thất bại khi gửi fastboot reboot: ${res.stderr}');
  } catch (e) {
    return (false, 'Lỗi Fastboot: $e');
  }
}

class FastbootToEdlWorker {
  final String serial;
  final Future<(bool, String)> Function(String) rebootAdb;
  final Future<(bool, String)> Function(String) rebootEdl;
  bool _aborted = false;

  final void Function(String serial, String message, String level)? onStep;
  final void Function(String adbSerial)? onAdbAppeared;
  final void Function(String serial, bool success, String message)? onDone;
  final void Function(String serial)? onNeedTestpoint;

  FastbootToEdlWorker({
    required this.serial,
    this.rebootAdb = fastbootRebootAdb,
    this.rebootEdl = adbRebootEdl,
    this.onStep,
    this.onAdbAppeared,
    this.onDone,
    this.onNeedTestpoint,
  });

  void abort() {
    _aborted = true;
  }

  /// Run the pipeline sequence: fastboot reboot -> wait adb -> adb reboot edl
  Future<void> run(DeviceManager deviceManager) async {
    bool finishIfAborted() {
      if (!_aborted) return false;
      onDone?.call(serial, false, 'Đã dừng.');
      return true;
    }

    void step(String msg, String level) {
      if (onStep != null) {
        onStep!(serial, msg, level);
      }
    }

    if (finishIfAborted()) return;

    step(tr('fb_pipe_start').replaceAll('{serial}', serial), 'info');

    // ── Step 1: fastboot reboot ──────────────────────────────────────────
    step(tr('fb_step1').replaceAll('{serial}', serial), 'info');
    final (ok1, msg1) = await rebootAdb(serial);
    if (finishIfAborted()) return;

    if (!ok1) {
      final err = tr('fb_step1_fail').replaceAll('{msg}', msg1);
      step(err, 'error');
      if (onNeedTestpoint != null) onNeedTestpoint!(serial);
      if (onDone != null) onDone!(serial, false, err);
      return;
    }

    step(tr('fb_step1_ok').replaceAll('{wait}', '$adbWaitSeconds'), 'info');

    // ── Step 2: Wait for ADB device ──────────────────────────────────────
    final stopwatch = Stopwatch()..start();
    final waitTimeoutMs = adbWaitSeconds * 1000;
    String? adbSerial;

    while (stopwatch.elapsedMilliseconds < waitTimeoutMs) {
      if (_aborted) {
        if (onDone != null) onDone!(serial, false, 'Đã dừng.');
        return;
      }

      try {
        await deviceManager.poll();
        if (finishIfAborted()) return;
        final adbDevs = deviceManager.knownAdb;
        for (final dev in adbDevs) {
          if (dev.isFastboot) continue;
          if (dev.state == 'unauthorized' || dev.state == 'offline') {
            continue;
          }
          // Never reboot an unrelated device when the target has not appeared.
          if (dev.serial == serial) {
            adbSerial = dev.serial;
            break;
          }
        }
      } catch (_) {}

      if (adbSerial != null) {
        break;
      }

      final remaining =
          adbWaitSeconds - (stopwatch.elapsedMilliseconds ~/ 1000);
      step(tr('fb_wait_adb').replaceAll('{remaining}', '$remaining'), 'info');
      await Future.delayed(pollInterval);
    }

    if (finishIfAborted()) return;

    if (adbSerial == null) {
      final err = tr('fb_adb_timeout').replaceAll('{wait}', '$adbWaitSeconds');
      step(err, 'error');
      if (onNeedTestpoint != null) onNeedTestpoint!(serial);
      if (onDone != null) onDone!(serial, false, err);
      return;
    }

    step(tr('fb_step2_ok').replaceAll('{serial}', adbSerial), 'success');
    if (onAdbAppeared != null) onAdbAppeared!(adbSerial);

    // Let ADB settle
    await Future.delayed(const Duration(seconds: 1));

    if (_aborted) {
      if (onDone != null) onDone!(serial, false, 'Đã dừng.');
      return;
    }

    // ── Step 3: adb reboot edl ───────────────────────────────────────────
    step(tr('fb_step3').replaceAll('{serial}', adbSerial), 'info');
    final (ok3, msg3) = await rebootEdl(adbSerial);
    if (finishIfAborted()) return;

    if (ok3) {
      step(tr('fb_step3_ok').replaceAll('{serial}', adbSerial), 'success');
      if (onDone != null) {
        onDone!(
          adbSerial,
          true,
          tr('fb_done_ok').replaceAll('{serial}', adbSerial),
        );
      }
    } else {
      final err3 = tr('fb_step3_fail').replaceAll('{msg}', msg3);
      step(err3, 'error');
      if (onDone != null) onDone!(adbSerial, false, err3);
    }
  }
}
