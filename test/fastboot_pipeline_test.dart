import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ja_iq5_flash/modules/logic/device_manager.dart';
import 'package:ja_iq5_flash/modules/logic/fastboot_to_edl_worker.dart';

class TargetManager extends DeviceManager {
  @override
  Future<void> poll() async {}

  @override
  List<AdbDevice> get knownAdb => [
    AdbDevice(serial: 'target', state: 'device', model: '', isFastboot: false),
  ];
}

void main() {
  test('bootloader fallback does not report EDL success', () async {
    final calls = <List<String>>[];
    final result = await adbRebootEdl(
      'target',
      commandRunner: (_, args) async {
        calls.add(args);
        return ProcessResult(1, calls.length == 1 ? 1 : 0, '', '');
      },
    );
    expect(result.$1, isFalse);
    expect(calls, [
      ['-s', 'target', 'reboot', 'edl'],
      ['-s', 'target', 'reboot', 'bootloader'],
    ]);
  });

  test('abort before run sends no command', () async {
    var commands = 0;
    final results = <bool>[];
    final worker = FastbootToEdlWorker(
      serial: 'target',
      rebootAdb: (_) async {
        commands++;
        return (true, 'ok');
      },
      onDone: (_, ok, _) => results.add(ok),
    );
    worker.abort();
    await worker.run(TargetManager());
    expect(commands, 0);
    expect(results, [false]);
  });

  test(
    'abort during reboot suppresses testpoint and subsequent steps',
    () async {
      final command = Completer<(bool, String)>();
      var testpoints = 0;
      var appeared = 0;
      final results = <bool>[];
      final worker = FastbootToEdlWorker(
        serial: 'target',
        rebootAdb: (_) => command.future,
        onNeedTestpoint: (_) => testpoints++,
        onAdbAppeared: (_) => appeared++,
        onDone: (_, ok, _) => results.add(ok),
      );
      final running = worker.run(TargetManager());
      worker.abort();
      command.complete((false, 'failed'));
      await running;
      expect(testpoints, 0);
      expect(appeared, 0);
      expect(results, [false]);
    },
  );

  testWidgets('abort during final EDL command cannot report success', (
    tester,
  ) async {
    final command = Completer<(bool, String)>();
    var edlCalls = 0;
    final results = <bool>[];
    final worker = FastbootToEdlWorker(
      serial: 'target',
      rebootAdb: (_) async => (true, 'ok'),
      rebootEdl: (_) {
        edlCalls++;
        return command.future;
      },
      onDone: (_, ok, _) => results.add(ok),
    );
    final running = worker.run(TargetManager());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(edlCalls, 1);
    worker.abort();
    command.complete((true, 'ok'));
    await tester.pump();
    await running;
    expect(results, [false]);
  });
}
