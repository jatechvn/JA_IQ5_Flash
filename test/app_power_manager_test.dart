import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_iq5_flash/modules/services/app_power_manager.dart';

void main() {
  group('AppPowerManager Unit Tests', () {
    late AppPowerManager powerManager;

    setUp(() {
      powerManager = AppPowerManager.create();
      powerManager.setEnableIdleSleep(true);
      powerManager.setIdleTimeout(const Duration(milliseconds: 100));
    });

    tearDown(() {
      powerManager.dispose();
    });

    test('Initial state: focused, visible, active animations', () {
      expect(powerManager.isWindowFocused, isTrue);
      expect(powerManager.isWindowVisible, isTrue);
      expect(powerManager.isUserIdle, isFalse);
      expect(powerManager.shouldAnimateBackground, isTrue);
      expect(powerManager.shouldAnimateIndicators, isTrue);
      expect(powerManager.shouldAnimateMarquee, isTrue);
      expect(powerManager.backgroundAnimationNotifier.value, isTrue);
      expect(powerManager.indicatorsAnimationNotifier.value, isTrue);
      expect(powerManager.marqueeAnimationNotifier.value, isTrue);
    });

    test('onWindowBlur pauses all 3 animation categories', () {
      powerManager.onWindowBlur();

      expect(powerManager.isWindowFocused, isFalse);
      expect(powerManager.shouldAnimateBackground, isFalse);
      expect(powerManager.shouldAnimateIndicators, isFalse);
      expect(powerManager.shouldAnimateMarquee, isFalse);
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);
      expect(powerManager.indicatorsAnimationNotifier.value, isFalse);
      expect(powerManager.marqueeAnimationNotifier.value, isFalse);
    });

    test('onWindowFocus resumes all animations', () {
      powerManager.onWindowBlur();
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);

      powerManager.onWindowFocus();
      expect(powerManager.isWindowFocused, isTrue);
      expect(powerManager.isWindowVisible, isTrue);
      expect(powerManager.isUserIdle, isFalse);
      expect(powerManager.backgroundAnimationNotifier.value, isTrue);
      expect(powerManager.indicatorsAnimationNotifier.value, isTrue);
      expect(powerManager.marqueeAnimationNotifier.value, isTrue);
    });

    test('onWindowMinimize marks window invisible and pauses all', () {
      powerManager.onWindowMinimize();
      expect(powerManager.isWindowVisible, isFalse);
      expect(powerManager.isWindowFocused, isFalse);
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);
      expect(powerManager.indicatorsAnimationNotifier.value, isFalse);
      expect(powerManager.marqueeAnimationNotifier.value, isFalse);
    });

    test(
      'onWindowRestore sets visible but does not force focus if unfocused',
      () {
        powerManager.onWindowMinimize();
        powerManager.onWindowRestore();

        expect(powerManager.isWindowVisible, isTrue);
        expect(powerManager.isWindowFocused, isFalse);
        expect(powerManager.backgroundAnimationNotifier.value, isFalse);

        powerManager.onWindowFocus();
        expect(powerManager.backgroundAnimationNotifier.value, isTrue);
      },
    );

    test('onLifecycleStateChanged maps Flutter lifecycle correctly', () {
      powerManager.onLifecycleStateChanged(AppLifecycleState.inactive);
      expect(powerManager.isWindowFocused, isFalse);
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);

      powerManager.onLifecycleStateChanged(AppLifecycleState.resumed);
      expect(powerManager.isWindowFocused, isTrue);
      expect(powerManager.backgroundAnimationNotifier.value, isTrue);

      powerManager.onLifecycleStateChanged(AppLifecycleState.hidden);
      expect(powerManager.isWindowVisible, isFalse);
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);

      powerManager.onLifecycleStateChanged(AppLifecycleState.paused);
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);
    });

    test(
      'Idle sleep pauses ONLY background, keeping indicators and marquee',
      () async {
        powerManager.setIdleTimeout(const Duration(milliseconds: 50));
        powerManager.onWindowFocus();

        expect(powerManager.backgroundAnimationNotifier.value, isTrue);
        expect(powerManager.indicatorsAnimationNotifier.value, isTrue);
        expect(powerManager.marqueeAnimationNotifier.value, isTrue);

        await Future.delayed(const Duration(milliseconds: 90));

        expect(powerManager.isUserIdle, isTrue);
        expect(powerManager.backgroundAnimationNotifier.value, isFalse);
        expect(powerManager.indicatorsAnimationNotifier.value, isTrue);
        expect(powerManager.marqueeAnimationNotifier.value, isTrue);
      },
    );

    test('User interaction wakes up idle background immediately', () async {
      powerManager.setIdleTimeout(const Duration(milliseconds: 40));
      powerManager.onWindowFocus();

      await Future.delayed(const Duration(milliseconds: 70));
      expect(powerManager.isUserIdle, isTrue);
      expect(powerManager.backgroundAnimationNotifier.value, isFalse);

      powerManager.recordUserInteraction();
      expect(powerManager.isUserIdle, isFalse);
      expect(powerManager.backgroundAnimationNotifier.value, isTrue);
    });

    test(
      'Disabling idle sleep prevents background animation from pausing',
      () async {
        powerManager.setEnableIdleSleep(false);
        powerManager.setIdleTimeout(const Duration(milliseconds: 40));
        powerManager.onWindowFocus();

        await Future.delayed(const Duration(milliseconds: 70));
        expect(powerManager.isUserIdle, isFalse);
        expect(powerManager.backgroundAnimationNotifier.value, isTrue);
      },
    );
  });
}
