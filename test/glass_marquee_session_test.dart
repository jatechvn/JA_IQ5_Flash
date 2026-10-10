import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_iq5_flash/modules/services/app_power_manager.dart';
import 'package:ja_iq5_flash/modules/ui/glass_widgets.dart';

void main() {
  final power = AppPowerManager.instance;

  setUp(() {
    power.resetForTesting(isFocused: true, isVisible: true, isIdle: false);
  });

  tearDown(() {
    power.onWindowBlur();
    power.resetForTesting(isFocused: true, isVisible: true, isIdle: false);
  });

  group('AsymmetricMarqueeText Session Epoch & Power Optimization Tests', () {
    testWidgets(
      'Marquee pauses and freezes offset on blur without ghost callback leaks',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 150,
                child: AsymmetricMarqueeText(
                  text:
                      'Extremely long text that will definitely exceed container width and scroll horizontally across the screen',
                  pauseStart: Duration(milliseconds: 50),
                  pauseEnd: Duration(milliseconds: 50),
                  velocity: 100.0,
                ),
              ),
            ),
          ),
        );

        // Initial pump for frame
        await tester.pump();
        expect(find.byType(AsymmetricMarqueeText), findsOneWidget);

        // Wait for pauseStart and start scrolling
        await tester.pump(const Duration(milliseconds: 60));
        await tester.pump(const Duration(milliseconds: 250));

        final scrollFinder = find.byType(SingleChildScrollView);
        expect(scrollFinder, findsOneWidget);
        final initialScroll = tester.widget<SingleChildScrollView>(
          scrollFinder,
        );
        expect(initialScroll.controller?.hasClients, isTrue);
        expect(initialScroll.controller!.offset, greaterThan(0));

        // Blur window
        power.onWindowBlur();
        final frozenOffset = initialScroll.controller!.offset;
        await tester.pump();

        // Pump extensive time while blurred - ensure no ghost timers or animation advances
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        expect(initialScroll.controller!.offset, equals(frozenOffset));

        // Resume focus
        power.onWindowFocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should continue scrolling from frozen offset
        expect(initialScroll.controller?.hasClients, isTrue);

        // Cleanup
        power.onWindowBlur();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('Marquee initialized while blurred remains frozen until focus', (
      tester,
    ) async {
      power.resetForTesting(isFocused: false, isVisible: true, isIdle: false);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: AsymmetricMarqueeText(
                text:
                    'Another very long scrolling text that starts while window is not focused',
                pauseStart: Duration(milliseconds: 50),
                velocity: 100.0,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scrollFinder = find.byType(SingleChildScrollView);
      final scroll = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(scroll.controller?.offset ?? 0.0, equals(0.0));

      // Now focus window
      power.onWindowFocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AsymmetricMarqueeText), findsOneWidget);

      // Cleanup
      power.onWindowBlur();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
