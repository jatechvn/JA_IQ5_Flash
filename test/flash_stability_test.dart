import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_iq5_flash/modules/logic/firmware_preflight.dart';
import 'package:ja_iq5_flash/modules/logic/operation_support.dart';
import 'package:ja_iq5_flash/modules/logic/reboot_tracker.dart';
import 'package:ja_iq5_flash/modules/logic/qfil_engine.dart';
import 'package:ja_iq5_flash/modules/logic/firmware_slot.dart';

void main() {
  test('cancelled queued engine never starts preflight or hardware', () async {
    final gate = Completer<void>();
    final first = DeviceOperationQueue.shared.run(() => gate.future);
    final engine = QfilEngine(port: 'TEST', fwDir: 'not-a-firmware');
    final pending = engine.run();
    engine.abort();
    gate.complete();
    await first;
    expect(await pending, isFalse);
    expect(engine.phase, 'queued');
  });

  test(
    'service restores original running state even when operation fails',
    () async {
      final calls = <String>[];
      var queries = 0;
      await expectLater(
        withQualcommService<void>(
          () async {
            calls.add('operation');
            throw StateError('fixture failure');
          },
          commandRunner: (_, args) async {
            calls.add(args.first);
            if (args.first == 'query') {
              return ProcessResult(
                0,
                0,
                'STATE : ${queries++ == 0 ? 4 : 1}',
                '',
              );
            }
            return ProcessResult(0, 0, '', '');
          },
        ),
        throwsStateError,
      );
      expect(calls, ['query', 'stop', 'query', 'operation', 'start']);
    },
    skip: !Platform.isWindows,
  );

  test(
    'service already stopped is never started by the app',
    () async {
      final calls = <String>[];
      final result = await withQualcommService(
        () async => 42,
        commandRunner: (_, args) async {
          calls.add(args.first);
          return ProcessResult(0, 0, 'STATE : 1 STOPPED', '');
        },
      );
      expect(result, 42);
      expect(calls, ['query']);
    },
    skip: !Platform.isWindows,
  );

  test('service access failure prevents device operation', () async {
    var ran = false;
    await expectLater(
      withQualcommService(() async {
        ran = true;
      }, commandRunner: (_, _) async => ProcessResult(0, 5, '', 'denied')),
      throwsStateError,
    );
    expect(ran, isFalse);
  }, skip: !Platform.isWindows);

  group('Firmware preflight', () {
    late Directory dir;
    void write(String name, String content) =>
        File('${dir.path}/$name').writeAsStringSync(content);
    setUp(() {
      dir = Directory.systemTemp.createTempSync('iq5_preflight_');
      write('prog_firehose_ddr.elf', 'programmer');
      write(
        'rawprogram_unsparse0.xml',
        '<data><program filename="boot.img"/><program filename=""/></data>',
      );
      write('patch0.xml', '<patches><patch filename="DISK"/></patches>');
      write('boot.img', 'image');
    });
    tearDown(() => dir.deleteSync(recursive: true));
    test('background slot validation matches preflight', () async {
      expect((await validateFirmwareSlot(dir.path)).isValid, isTrue);
    });
    test('accepts images, skipped entries and DISK patches', () {
      expect(validateFirmware(dir.path), isEmpty);
    });
    test('rejects missing referenced image', () {
      File('${dir.path}/boot.img').deleteSync();
      expect(validateFirmware(dir.path).join(), contains('boot.img'));
    });
    test('rejects empty image and empty programmer', () {
      write('boot.img', '');
      expect(validateFirmware(dir.path).join(), contains('boot.img'));
      write('prog_firehose_ddr.elf', '');
      expect(validateFirmware(dir.path).join(), contains('prog_firehose'));
    });
    test('rejects malformed XML', () {
      write('rawprogram_unsparse0.xml', '<data><program></data>');
      expect(validateFirmware(dir.path), isNotEmpty);
    });
    test('rejects traversal and absolute paths', () {
      for (final path in ['../secret.img', 'C:/secret.img', '/secret.img']) {
        write(
          'rawprogram_unsparse0.xml',
          '<data><program filename="$path"/></data>',
        );
        expect(validateFirmware(dir.path).join(), contains('Unsafe'));
      }
    });
    test('rejects XML without program images', () {
      write('rawprogram_unsparse0.xml', '<data/>');
      expect(validateFirmware(dir.path).join(), contains('No program images'));
    });
  });

  test('reboot confirmation cannot consume an unrelated online device', () {
    final tracker = RebootTracker();
    tracker.expect('target', {'target', 'other'});
    expect(tracker.observe({'target', 'other'}), isEmpty);
    expect(tracker.observe({'other'}), isEmpty);
    expect(tracker.observe({'target', 'other'}), {'target'});
    expect(tracker.observe({'target'}), isEmpty);
  });
  test('unknown identity requires manual verification', () {
    final tracker = RebootTracker()..expect('', {});
    expect(tracker.hasUnknown, isTrue);
    expect(tracker.observe({'unrelated'}), isEmpty);
    tracker.clear();
    expect(tracker.hasUnknown, isFalse);
  });
  test('queue serializes operations and recovers after failure', () async {
    final queue = DeviceOperationQueue();
    final gate = Completer<void>();
    final events = <int>[];
    final first = queue.run(() async {
      events.add(1);
      await gate.future;
      throw StateError('fixture');
    });
    final failed = expectLater(first, throwsStateError);
    final second = queue.run(() async {
      events.add(2);
      return true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(events, [1]);
    gate.complete();
    await failed;
    expect(await second, isTrue);
    expect(events, [1, 2]);
  });
  test(
    'process consumes both pipes and respects nonzero exit',
    () async {
      final lines = <String>[];
      final code = await ManagedProcess().run('powershell.exe', [
        '-NoProfile',
        '-Command',
        '[Console]::Out.WriteLine("out"); [Console]::Error.WriteLine("err"); exit 7',
      ], onLine: (line, error) => lines.add(line));
      expect(code, 7);
      expect(lines, containsAll(['out', 'err']));
    },
    skip: !Platform.isWindows,
  );
  test('silent process timeout ends the operation', () async {
    await expectLater(
      ManagedProcess().run('powershell.exe', [
        '-NoProfile',
        '-Command',
        'Start-Sleep -Seconds 60',
      ], idleTimeout: const Duration(milliseconds: 300)),
      throwsA(isA<TimeoutException>()),
    );
  }, skip: !Platform.isWindows);
  test('abort terminates an active process', () async {
    final process = ManagedProcess();
    final running = process.run('powershell.exe', [
      '-NoProfile',
      '-Command',
      '[Console]::Out.WriteLine("ready"); Start-Sleep -Seconds 60',
    ], onLine: (_, _) => process.abort());
    await expectLater(running, throwsStateError);
  }, skip: !Platform.isWindows);
}
