import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ja_iq5_flash/modules/ui/device_card.dart';
import 'package:ja_iq5_flash/modules/ui/styles.dart';
import 'package:ja_iq5_flash/modules/i18n.dart';
import 'package:ja_iq5_flash/modules/logic/device_manager.dart';
import 'package:ja_iq5_flash/modules/logic/firmware_slot.dart';
import 'package:ja_iq5_flash/modules/logic/flash_isolate.dart';
import 'package:ja_iq5_flash/modules/logic/flash_session.dart';
import 'package:ja_iq5_flash/modules/logic/qfil_engine.dart';

class FakeEngine extends QfilEngine {
  FakeEngine(String directory) : super(port: 'TEST', fwDir: directory);
  final result = Completer<bool>();
  bool aborted = false;

  @override
  void abort() => aborted = true;

  @override
  Future<bool> run({
    void Function(int)? onProgress,
    void Function(String, String)? onLog,
    void Function(bool, String)? onDone,
  }) async {
    final ok = await result.future;
    onProgress?.call(100);
    onLog?.call('completed', 'info');
    onDone?.call(ok, 'completed');
    return ok;
  }
}

FlashSession sessionWith(QfilEngine Function(String) factory) => FlashSession(
  device: DeviceInfo(port: 'TEST', description: '', hwid: '', serialNumber: ''),
  fwDir: 'old-rom',
  engineFactory: factory,
);

void main() {
  testWidgets('disconnected card disables flash and reboot controls', (
    tester,
  ) async {
    final session = sessionWith((_) => FakeEngine('rom'));
    addTearDown(session.dispose);
    session.disconnected();
    setLang('EN');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 650,
            height: 450,
            child: DeviceCard(
              session: session,
              theme: AppTheme(),
              autoFlashLocked: false,
              onFlashRequested: (_) => fail('disconnected flash'),
              onAbortRequested: (_) {},
              onRemoveRequested: (_) {},
              onRebootRequested: (_) => fail('disconnected reboot'),
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Offline'), findsOneWidget);
    final buttons = tester.widgetList<ElevatedButton>(
      find.byType(ElevatedButton),
    );
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);
    expect(tester.takeException(), isNull);
  });

  test(
    'disconnect during writing fails and blocks reuse of disconnected port',
    () async {
      final engine = FakeEngine('rom')..phase = 'writing';
      final session = sessionWith((_) => engine);
      addTearDown(session.dispose);
      final running = session.start();
      session.disconnected();
      expect(engine.aborted, isTrue);
      engine.result.complete(true);
      expect(await running, isFalse);
      expect(session.status, FlashSession.statusError);
      expect(session.logs, contains(contains('disconnected')));
      expect(await session.start(), isFalse);
    },
  );

  test('expected reset disconnect preserves actual engine result', () async {
    final engine = FakeEngine('rom')..phase = 'resetting';
    final session = sessionWith((_) => engine);
    addTearDown(session.dispose);
    final running = session.start();
    session.disconnected();
    expect(engine.aborted, isFalse);
    engine.result.complete(true);
    expect(await running, isTrue);
    expect(session.status, FlashSession.statusSuccess);
    expect(session.connected, isFalse);
  });

  test('session log memory is bounded', () {
    final session = sessionWith((_) => FakeEngine('rom'));
    addTearDown(session.dispose);
    for (var i = 0; i < 1500; i++) {
      session.appendLog('$i');
    }
    expect(session.logs.length, 1000);
    expect(session.logs.first, '500');
  });

  test('abort from running listener prevents engine startup', () async {
    var starts = 0;
    final session = sessionWith((_) {
      starts++;
      return FakeEngine('rom')..result.complete(true);
    });
    addTearDown(session.dispose);
    session.addListener(() {
      if (session.status == FlashSession.statusRunning) session.abort();
    });
    expect(await session.start(), isFalse);
    expect(starts, 0);
    expect(session.isRunning, isFalse);
    expect(session.status, FlashSession.statusAborted);
  });

  test(
    'flash uses firmware selected at start and publishes final status',
    () async {
      late FakeEngine engine;
      final session = sessionWith((path) => engine = FakeEngine(path));
      addTearDown(session.dispose);
      String? completedStatus;
      session.onDone = (_, _, _) => completedStatus = session.status;
      final running = session.start(firmwareDirectory: 'selected-rom');
      expect(engine.fwDir, 'selected-rom');
      engine.result.complete(true);
      expect(await running, isTrue);
      expect(completedStatus, FlashSession.statusSuccess);
    },
  );

  test(
    'abort preserves status and blocks restart until engine settles',
    () async {
      final engine = FakeEngine('rom');
      final session = sessionWith((_) => engine);
      addTearDown(session.dispose);
      final running = session.start();
      expect(await session.start(), isFalse);
      session.abort();
      expect(engine.aborted, isTrue);
      expect(session.isRunning, isTrue);
      expect(await session.start(), isFalse);
      engine.result.complete(true);
      expect(await running, isFalse);
      expect(session.status, FlashSession.statusAborted);
      expect(session.isRunning, isFalse);
    },
  );

  test('abort does not change an idle or completed session', () async {
    final engine = FakeEngine('rom');
    final session = sessionWith((_) => engine);
    addTearDown(session.dispose);
    session.abort();
    expect(session.status, FlashSession.statusIdle);
    engine.result.complete(true);
    await session.start();
    session.abort();
    expect(session.status, FlashSession.statusSuccess);
  });

  test('engine exception ends running state and reports failure', () async {
    final engine = FakeEngine('rom');
    final session = sessionWith((_) => engine);
    addTearDown(session.dispose);
    var completions = 0;
    session.onDone = (_, ok, message) {
      expect(ok, isFalse);
      expect(message, contains('test failure'));
      completions++;
    };
    final running = session.start();
    engine.result.completeError(StateError('test failure'));
    expect(await running, isFalse);
    expect(session.status, FlashSession.statusError);
    expect(session.isRunning, isFalse);
    expect(completions, 1);
  });

  test(
    'disposing active session aborts and suppresses late callbacks',
    () async {
      final engine = FakeEngine('rom');
      final session = sessionWith((_) => engine);
      var callbacks = 0;
      session.onDone = (_, _, _) => callbacks++;
      session.onLogMessage = (_, _, _) => callbacks++;
      session.onProgressChanged = (_, _) => callbacks++;
      final running = session.start();
      session.dispose();
      expect(engine.aborted, isTrue);
      engine.result.complete(true);
      expect(await running, isFalse);
      expect(callbacks, 0);
    },
  );

  test('Sahara abort during spawn resolves without waiting forever', () async {
    final handle = SaharaIsolateHandle();
    final running = handle.run(
      port: 'INVALID_TEST_PORT',
      elfPath: 'missing-test.elf',
    );
    handle.abort();
    final result = await running.timeout(const Duration(seconds: 5));
    expect(result.$1, isFalse);
  });

  test('Sahara missing programmer returns failure', () async {
    final result = await SaharaIsolateHandle()
        .run(port: 'INVALID_TEST_PORT', elfPath: 'missing-test.elf')
        .timeout(const Duration(seconds: 5));
    expect(result.$1, isFalse);
  });

  test('firmware validation rejects programmer unsupported by engine', () {
    final dir = Directory.systemTemp.createTempSync('iq5_validation_');
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final name in [
      'rawprogram_unsparse0.xml',
      'patch0.xml',
      'prog_other.mbn',
    ]) {
      File('${dir.path}/$name').writeAsStringSync('fixture');
    }
    final slot = FirmwareSlotProfile(
      index: 0,
      type: FirmwareSlotType.factory,
      customName: '',
      path: dir.path,
    );
    expect(slot.validate().isValid, isFalse);
    expect(slot.lastValidation.missingFiles, contains('prog_firehose_ddr.elf'));
  });
}
