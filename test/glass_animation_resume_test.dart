import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_iq5_flash/modules/services/app_power_manager.dart';
import 'package:ja_iq5_flash/modules/ui/glass_widgets.dart';

void main() {
  final power = AppPowerManager.instance;

  setUp(() {
    power.setEnableIdleSleep(true);
    power.resetForTesting();
  });

  tearDown(() {
    power.onWindowBlur();
    power.resetForTesting();
  });

  AnimationController controllerFor(WidgetTester tester, Widget widget) {
    final builder = tester.widget<AnimatedBuilder>(
      find.descendant(
        of: find.byType(widget.runtimeType),
        matching: find.byType(AnimatedBuilder),
      ),
    );
    return builder.animation as AnimationController;
  }

  group('MeshOrb Direction Preservation & Power Optimization Tests', () {
    const orbWidget = MeshOrb(
      color: Colors.blue,
      size: 200,
      duration: Duration(milliseconds: 1000),
      travel: Offset(50, 50),
    );

    for (final reverse in [false, true]) {
      testWidgets(
        'MeshOrb preserves ${reverse ? 'reverse' : 'forward'} leg across blur/focus',
        (tester) async {
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: orbWidget)),
          );
          await tester.pump();
          final controller = controllerFor(tester, orbWidget);

          if (reverse) {
            // Let it complete forward and start reverse leg
            await tester.pump(controller.duration!);
            await tester.pump();
          }
          await tester.pump(const Duration(milliseconds: 250));

          final expectedStatus = reverse
              ? AnimationStatus.reverse
              : AnimationStatus.forward;
          expect(controller.status, expectedStatus);

          for (var cycle = 0; cycle < 2; cycle++) {
            power.onWindowBlur();
            final frozen = controller.value;
            expect(controller.isAnimating, isFalse);

            await tester.pump(const Duration(milliseconds: 500));
            expect(controller.value, frozen);

            power.onWindowFocus();
            expect(controller.value, frozen);
            expect(controller.status, expectedStatus);

            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));
            expect(
              controller.value,
              reverse ? lessThan(frozen) : greaterThan(frozen),
            );
          }

          // Cleanup invariants
          power.onWindowBlur();
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets('RotatingGlowBorder pauses on blur and resumes on focus', (
      tester,
    ) async {
      const glowWidget = RotatingGlowBorder(
        isActive: true,
        color: Colors.cyan,
        duration: Duration(milliseconds: 1000),
        child: SizedBox(width: 100, height: 100),
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: glowWidget)),
      );

      expect(find.byType(RotatingGlowBorder), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));

      // Blur window
      power.onWindowBlur();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Focus window
      power.onWindowFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(RotatingGlowBorder), findsOneWidget);

      // Cleanup
      power.onWindowBlur();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
