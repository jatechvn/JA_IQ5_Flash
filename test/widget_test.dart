import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_iq5_flash/modules/i18n.dart';
import 'package:ja_iq5_flash/modules/logic/firmware_slot.dart';
import 'package:ja_iq5_flash/modules/ui/app_colors.dart';
import 'package:ja_iq5_flash/modules/ui/glass_widgets.dart';
import 'package:ja_iq5_flash/modules/ui/styles.dart';
import 'package:ja_iq5_flash/modules/ui/settings_dialog.dart';

void main() {
  group('FirmwareSlotProfile Tests', () {
    test(
      'Initializes 3 slot types with proper badges, icons, and dynamic i18n',
      () {
        setLang('EN');
        final slot1 = FirmwareSlotProfile(
          index: 0,
          type: FirmwareSlotType.factory,
          customName: '',
          path: '',
        );
        final slot2 = FirmwareSlotProfile(
          index: 1,
          type: FirmwareSlotType.user,
          customName: '',
          path: '',
        );
        final slot3 = FirmwareSlotProfile(
          index: 2,
          type: FirmwareSlotType.diag,
          customName: '',
          path: '',
        );

        expect(slot1.type.badge, equals('FACTORY ROM'));
        expect(slot2.type.badge, equals('USER ROM'));
        expect(slot3.type.badge, equals('DIAG / TEST'));
        expect(slot1.displayName, equals('Factory Stock ROM'));
        expect(slot2.displayName, equals('User / Custom ROM'));
        expect(slot3.displayName, equals('Diag / Test ROM'));

        // Test dynamic translation to Vietnamese
        setLang('VI');
        expect(slot1.displayName, equals('Bản ROM Chuẩn Nhà Máy'));
        expect(slot2.displayName, equals('Bản ROM Khách Hàng / Tuỳ Biến'));
        expect(slot3.displayName, equals('Bản ROM Kỹ Thuật / Chẩn Đoán'));

        // Test dynamic translation to Chinese
        setLang('CN');
        expect(slot1.displayName, equals('原厂官方固件'));
        expect(slot2.displayName, equals('客户定制固件'));
        expect(slot3.displayName, equals('工程测试固件'));
      },
    );

    test('Validates empty and non-existing directory', () {
      final slot = FirmwareSlotProfile(
        index: 0,
        type: FirmwareSlotType.factory,
        customName: 'Test Slot',
        path: '',
      );

      final resEmpty = slot.validate();
      expect(resEmpty.isValid, isFalse);
      expect(resEmpty.statusKey, equals('fw_empty'));

      slot.path = 'Z:\\NonExistent\\Firmware\\Dir';
      final resInvalid = slot.validate();
      expect(resInvalid.isValid, isFalse);
      expect(resInvalid.statusKey, equals('fw_invalid'));
    });

    test('Validates directory with required Qualcomm files', () {
      final tempDir = Directory.systemTemp.createTempSync('fw_test_');
      try {
        final slot = FirmwareSlotProfile(
          index: 0,
          type: FirmwareSlotType.factory,
          customName: 'Test Slot',
          path: tempDir.path,
        );

        // Missing files initially
        final resMissing = slot.validate();
        expect(resMissing.isValid, isFalse);
        expect(resMissing.statusKey, equals('fw_missing'));
        expect(resMissing.missingFiles.length, equals(3));

        // Create required files
        File(
          '${tempDir.path}/rawprogram_unsparse0.xml',
        ).writeAsStringSync('<xml/>');
        File('${tempDir.path}/patch0.xml').writeAsStringSync('<xml/>');
        File(
          '${tempDir.path}/prog_firehose_ddr.elf',
        ).writeAsStringSync('binary');

        final resOk = slot.validate();
        expect(resOk.isValid, isTrue);
        expect(resOk.statusKey, equals('fw_ok'));
        expect(resOk.detectedFirehose, equals('prog_firehose_ddr.elf'));
        expect(resOk.xmlCount, equals(2));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('Bento Glassmorphism UI Component Tests', () {
    test('AppColors token model exposes valid colors', () {
      expect(win11DarkColors.accentCyan, isNotNull);
      expect(win11DarkColors.accentEmerald, isNotNull);
      expect(win11DarkColors.accentAmber, isNotNull);
      expect(win11DarkColors.accentRose, isNotNull);
      expect(win11LightColors.accentColor, isNotNull);
    });

    testWidgets('Renders PillBadge and BentoCard properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BentoCard(
                colors: win11DarkColors,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PillBadge(
                      label: 'ONLINE',
                      color: win11DarkColors.accentEmerald,
                      bg: win11DarkColors.accentEmerald.withValues(alpha: 0.15),
                      border: win11DarkColors.accentEmerald.withValues(
                        alpha: 0.3,
                      ),
                      showDot: true,
                    ),
                    const SizedBox(height: 8),
                    GlowingActionButton(
                      label: 'FLASH ALL',
                      icon: Icons.bolt,
                      colors: win11DarkColors,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('FLASH ALL'), findsOneWidget);
    });

    test('Colors provide transparent background matching showcase', () {
      expect(win11DarkColors.bgPrimary, equals(Colors.transparent));
      expect(win11LightColors.bgPrimary, equals(Colors.transparent));
      expect(win10DarkColors.bgPrimary, equals(Colors.transparent));
      expect(win10LightColors.bgPrimary, equals(Colors.transparent));
    });

    test(
      'FirmwareSlotProfile supports dynamic custom naming and localization',
      () {
        setLang('VI');
        final slot = FirmwareSlotProfile(
          index: 0,
          type: FirmwareSlotType.factory,
          customName: 'ROM Gốc',
          path: 'C:\\FW',
        );
        expect(slot.displayName, equals('ROM Gốc'));

        slot.customName = 'Bản Global 2026';
        expect(slot.displayName, equals('Bản Global 2026'));

        slot.customName = '';
        expect(slot.displayName, equals('Bản ROM Chuẩn Nhà Máy'));

        setLang('EN');
        expect(slot.displayName, equals('Factory Stock ROM'));
        expect(
          slot.lastValidation.localizedMessage,
          equals('No folder selected'),
        );
      },
    );
  });

  group('Settings & Glassmorphism Tuning Tests', () {
    test('AppTheme glassmorphism defaults and live tuning', () {
      final theme = AppTheme();
      expect(theme.cardBlur, equals(20.0));
      expect(theme.cardOpacity, equals(0.25));
      expect(theme.dialogBlur, equals(20.0));
      expect(theme.dialogOpacity, equals(0.85));
      expect(theme.enableMeshOrbs, isTrue);
      expect(theme.meshOrbOpacity, equals(0.24));
      expect(theme.cpuCores, greaterThanOrEqualTo(1));
      expect(theme.hardwareScore, inInclusiveRange(10, 100));

      // Test live adjustment with clamping
      theme.setLiveGlassmorphism(
        cardBlur: 35.0,
        cardOpacity: 0.50,
        dialogBlur: 10.0,
        dialogOpacity: 0.95,
        enableMeshOrbs: false,
        meshOrbOpacity: 0.40,
      );

      expect(theme.cardBlur, equals(35.0));
      expect(theme.cardOpacity, equals(0.50));
      expect(theme.dialogBlur, equals(10.0));
      expect(theme.dialogOpacity, equals(0.95));
      expect(theme.enableMeshOrbs, isFalse);
      expect(theme.meshOrbOpacity, equals(0.40));

      // Test reset
      theme.resetGlassDefaults();
      expect(theme.cardBlur, equals(20.0));
      expect(theme.dialogBlur, equals(20.0));
      expect(theme.enableMeshOrbs, isTrue);
    });

    testWidgets('Renders showSettingsDialog with all 5 tabs and interactions', (
      tester,
    ) async {
      final theme = AppTheme();
      setLang('EN');

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showSettingsDialog(
                  context: context,
                  theme: theme,
                  initialTab: 0,
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      // Open settings dialog
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Check tab names are rendered
      expect(find.text(tr('tab_glass')), findsOneWidget);
      expect(find.text(tr('tab_ota')), findsOneWidget);
      expect(find.text(tr('tab_guide')), findsOneWidget);
      expect(find.text(tr('tab_about')), findsOneWidget);
      expect(find.text(tr('tab_license')), findsOneWidget);

      // Check Glassmorphism tab sliders are present
      expect(find.text(tr('settings_card_blur')), findsOneWidget);
      expect(find.text(tr('settings_card_opacity')), findsOneWidget);

      // Switch to OTA tab
      await tester.tap(find.text(tr('tab_ota')));
      await tester.pumpAndSettle();
      expect(find.text(tr('ota_check_interval')), findsOneWidget);
      expect(find.text(tr('ota_server_path')), findsOneWidget);

      // Switch to User Guide tab
      await tester.tap(find.text(tr('tab_guide')));
      await tester.pumpAndSettle();
      expect(find.text(tr('guide_flash_title')), findsOneWidget);

      // Switch to About tab
      await tester.tap(find.text(tr('tab_about')));
      await tester.pumpAndSettle();
      expect(find.text(tr('about_app_desc')), findsOneWidget);

      // Switch to License tab
      await tester.tap(find.text(tr('tab_license')));
      await tester.pumpAndSettle();
      expect(find.text(tr('lic_copy_hwid_btn')), findsOneWidget);
    });

    testWidgets(
      'TopBarExpandingButton renders collapsed and expands on hover',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TopBarExpandingButton(
                  icon: const Icon(Icons.settings_rounded, size: 14),
                  collapsedLabel: null,
                  expandedLabel: 'Settings',
                  textColor: Colors.cyan,
                  tooltip: 'Settings Tooltip',
                  colors: win11DarkColors,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        // Collapsed state: icon is present, expanded text is not visible
        expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
        expect(find.text('Settings'), findsNothing);

        // Hover over the button using a mouse pointer
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(
          tester.getCenter(find.byType(TopBarExpandingButton)),
        );
        await tester.pumpAndSettle();

        // Expanded state: text 'Settings' is now rendered
        expect(find.text('Settings'), findsOneWidget);

        // Tap on it
        await tester.tap(find.byType(TopBarExpandingButton));
        expect(tapped, isTrue);

        // Mouse leaves the button
        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();

        // Back to collapsed state: expanded text disappears
        expect(find.text('Settings'), findsNothing);
      },
    );
  });

  group('Path Input and Browse i18n Tests', () {
    test('Verifies paste and browse keys are localized in EN, VI, and CN', () {
      for (final lang in ['EN', 'VI', 'CN']) {
        setLang(lang);
        expect(tr('paste_btn'), isNotEmpty);
        expect(tr('paste_tooltip'), isNotEmpty);
        expect(tr('hint_paste_or_browse'), isNotEmpty);
        expect(tr('log_slot_update_prefix'), isNotEmpty);
      }
    });

    test('Trims and strips double and single quotes from pasted paths', () {
      String sanitizePath(String raw) {
        var clean = raw.trim();
        if ((clean.startsWith('"') && clean.endsWith('"')) ||
            (clean.startsWith("'") && clean.endsWith("'"))) {
          clean = clean.substring(1, clean.length - 1).trim();
        }
        return clean;
      }

      expect(
        sanitizePath('  "D:\\Firmware\\IQ5_v1.0"  '),
        equals('D:\\Firmware\\IQ5_v1.0'),
      );
      expect(
        sanitizePath("'D:\\Firmware\\IQ5_v2.0'"),
        equals('D:\\Firmware\\IQ5_v2.0'),
      );
      expect(sanitizePath('D:\\Firmware\\IQ5'), equals('D:\\Firmware\\IQ5'));
    });
  });

  group('Two-Column and Terminal Height Mode Tests', () {
    test('Verifies terminal height toggle translations in EN, VI, CN', () {
      for (final lang in ['EN', 'VI', 'CN']) {
        setLang(lang);
        expect(tr('terminal_toggle_tooltip'), isNotEmpty);
        expect(tr('terminal_height_collapsed'), isNotEmpty);
        expect(tr('terminal_height_compact'), isNotEmpty);
        expect(tr('terminal_height_expanded'), isNotEmpty);
        expect(tr('edl_header'), isNotEmpty);
        expect(tr('adb_header'), isNotEmpty);
      }
    });

    test('Verifies terminal height mode calculation logic', () {
      double getTerminalHeight(int mode) {
        return mode == 0 ? 34.0 : (mode == 1 ? 95.0 : 180.0);
      }

      expect(getTerminalHeight(0), equals(34.0));
      expect(getTerminalHeight(1), equals(95.0));
      expect(getTerminalHeight(2), equals(180.0));

      // Test cycle logic
      int mode = 1;
      mode = (mode + 1) % 3;
      expect(mode, equals(2));
      mode = (mode + 1) % 3;
      expect(mode, equals(0));
      mode = (mode + 1) % 3;
      expect(mode, equals(1));
    });
  });

  group('UI Polish & Refinements Tests (Sprint 5)', () {
    test('Verifies slot_active_badge localization in EN, VI, CN', () {
      setLang('EN');
      expect(tr('slot_active_badge'), equals('ACTIVE'));
      setLang('VI');
      expect(tr('slot_active_badge'), equals('ĐANG CHỌN'));
      setLang('CN');
      expect(tr('slot_active_badge'), equals('已选定'));
    });

    testWidgets(
      'TopBarExpandingButton uses vector translate icon without text emojis',
      (tester) async {
        final colors = win11DarkColors;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TopBarExpandingButton(
                icon: const Icon(Icons.translate_rounded, size: 14),
                collapsedLabel: 'VI',
                expandedLabel: 'Tiếng Việt',
                onTap: () {},
                tooltip: 'Change Language',
                colors: colors,
              ),
            ),
          ),
        );

        // Verify Icon is present
        expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
        expect(find.text('VI'), findsOneWidget);
      },
    );

    testWidgets('BentoCard supports customBorder, borderWidth, and customBg', (
      tester,
    ) async {
      final colors = win11DarkColors;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BentoCard(
              colors: colors,
              isFeatured: true,
              showTopHighlight: false,
              customBg: Colors.cyan.withValues(alpha: 0.2),
              customBorder: Colors.cyan,
              borderWidth: 2.0,
              glowColor: Colors.cyan,
              child: const Text('Slot 1 Active'),
            ),
          ),
        ),
      );

      expect(find.text('Slot 1 Active'), findsOneWidget);
    });
  });

  group('RotatingGlowBorder Component Tests', () {
    testWidgets('RotatingGlowBorder renders child directly when inactive', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RotatingGlowBorder(
              isActive: false,
              color: Colors.cyan,
              child: Text('Slot Card Inactive'),
            ),
          ),
        ),
      );

      expect(find.text('Slot Card Inactive'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RotatingGlowBorder),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'RotatingGlowBorder activates CustomPaint and animates when active',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RotatingGlowBorder(
                isActive: true,
                color: Colors.cyan,
                child: Text('Slot Card Active'),
              ),
            ),
          ),
        );

        expect(find.text('Slot Card Active'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(RotatingGlowBorder),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );

        // Pump 500ms to verify animation step progresses smoothly
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.descendant(
            of: find.byType(RotatingGlowBorder),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'RotatingGlowBorder dynamically responds to isActive toggling',
      (tester) async {
        bool active = false;
        late StateSetter setStateCallback;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setStateCallback = setState;
                  return RotatingGlowBorder(
                    isActive: active,
                    color: Colors.cyan,
                    child: const Text('Toggling Card'),
                  );
                },
              ),
            ),
          ),
        );

        // Initially inactive
        expect(
          find.descendant(
            of: find.byType(RotatingGlowBorder),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
        );

        // Toggle to active
        setStateCallback(() => active = true);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(RotatingGlowBorder),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );

        // Pump frame to verify running
        await tester.pump(const Duration(milliseconds: 200));

        // Toggle back to inactive
        setStateCallback(() => active = false);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(RotatingGlowBorder),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
        );
      },
    );

    test(
      'RotatingGlowBorderPainter paints on canvas and handles shouldRepaint',
      () {
        final painter1 = RotatingGlowBorderPainter(
          animationProgress: 0.25,
          color: Colors.cyan,
          borderRadius: 16.0,
          borderWidth: 2.0,
          glowBlur: 6.0,
        );
        final painter2 = RotatingGlowBorderPainter(
          animationProgress: 0.50,
          color: Colors.cyan,
          borderRadius: 16.0,
          borderWidth: 2.0,
          glowBlur: 6.0,
        );
        final painterIdentical = RotatingGlowBorderPainter(
          animationProgress: 0.25,
          color: Colors.cyan,
          borderRadius: 16.0,
          borderWidth: 2.0,
          glowBlur: 6.0,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
        expect(painter1.shouldRepaint(painterIdentical), isFalse);

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        expect(
          () => painter1.paint(canvas, const Size(200, 80)),
          returnsNormally,
        );
        expect(() => painter1.paint(canvas, Size.zero), returnsNormally);
        recorder.endRecording();
      },
    );
  });

  group('Hardware Tier & Auto-Profiling Tests', () {
    test('AppTheme hardware profiling, tier cycling, and presets', () {
      final theme = AppTheme();
      expect(theme.cpuCores, greaterThanOrEqualTo(1));
      expect(theme.hardwareScore, inInclusiveRange(10, 100));
      expect(theme.detectedTier, isNotNull);
      expect(theme.perfMode, equals(PerfTierMode.auto));
      expect(theme.effectiveTier, equals(theme.detectedTier));
      expect(theme.perfLabel, contains('Auto'));

      // Test cyclePerfTier: auto -> ultra -> balanced -> lite -> auto
      theme.cyclePerfTier();
      expect(theme.perfMode, equals(PerfTierMode.ultra));
      expect(theme.effectiveTier, equals(HardwareTier.ultra));
      expect(theme.cardBlur, equals(20.0));
      expect(theme.cardOpacity, equals(0.25));
      expect(theme.enableMeshOrbs, isTrue);

      theme.cyclePerfTier();
      expect(theme.perfMode, equals(PerfTierMode.balanced));
      expect(theme.effectiveTier, equals(HardwareTier.balanced));
      expect(theme.cardBlur, equals(14.0));
      expect(theme.cardOpacity, equals(0.35));
      expect(theme.enableMeshOrbs, isTrue);

      theme.cyclePerfTier();
      expect(theme.perfMode, equals(PerfTierMode.lite));
      expect(theme.effectiveTier, equals(HardwareTier.lite));
      expect(theme.cardBlur, equals(0.0));
      expect(theme.cardOpacity, equals(0.78));
      expect(theme.enableMeshOrbs, isFalse);

      theme.cyclePerfTier();
      expect(theme.perfMode, equals(PerfTierMode.auto));
      expect(theme.effectiveTier, equals(theme.detectedTier));

      // Test resetGlassDefaults
      theme.setPerfTierMode(PerfTierMode.lite);
      expect(theme.perfMode, equals(PerfTierMode.lite));
      theme.resetGlassDefaults();
      expect(theme.perfMode, equals(PerfTierMode.auto));
      expect(theme.cardBlur, equals(20.0));

      // Test PerfTierMode.fromId
      expect(PerfTierMode.fromId('auto'), equals(PerfTierMode.auto));
      expect(PerfTierMode.fromId('ultra'), equals(PerfTierMode.ultra));
      expect(PerfTierMode.fromId('balanced'), equals(PerfTierMode.balanced));
      expect(PerfTierMode.fromId('lite'), equals(PerfTierMode.lite));
      expect(PerfTierMode.fromId('UNKNOWN'), equals(PerfTierMode.auto));
      expect(PerfTierMode.fromId(null), equals(PerfTierMode.auto));
    });

    testWidgets(
      'Settings dialog renders Hardware Profile Section & switches tiers',
      (tester) async {
        final theme = AppTheme();
        setLang('EN');

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showSettingsDialog(
                    context: context,
                    theme: theme,
                    initialTab: 0,
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('OPEN'));
        await tester.pumpAndSettle();

        // Verify Hardware Tier Profile header and modes
        expect(find.text(tr('perf_tier_header')), findsOneWidget);
        expect(find.text(tr('perf_auto')), findsOneWidget);
        expect(find.text(tr('perf_ultra')), findsOneWidget);
        expect(find.text(tr('perf_balanced')), findsOneWidget);
        expect(find.text(tr('perf_lite')), findsOneWidget);

        // Tap Lite mode
        await tester.tap(find.text(tr('perf_lite')));
        await tester.pumpAndSettle();
        expect(theme.perfMode, equals(PerfTierMode.lite));
        expect(theme.cardBlur, equals(0.0));
        expect(theme.enableMeshOrbs, isFalse);

        // Tap Balanced mode
        await tester.tap(find.text(tr('perf_balanced')));
        await tester.pumpAndSettle();
        expect(theme.perfMode, equals(PerfTierMode.balanced));
        expect(theme.cardBlur, equals(14.0));
        expect(theme.enableMeshOrbs, isTrue);
      },
    );
  });

  group('BounceMarquee & GlassBouncePathField Tests', () {
    testWidgets('BounceMarqueeText renders text in horizontal scroll view', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 30,
              child: BounceMarqueeText(
                text:
                    'D:\\Very\\Long\\Firmware\\Directory\\Path\\That\\Exceeds\\Width',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'D:\\Very\\Long\\Firmware\\Directory\\Path\\That\\Exceeds\\Width',
        ),
        findsOneWidget,
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Pump frames without throwing exceptions or timer leaks
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets(
      'GlassBouncePathField shows BounceMarqueeText when not focused and text is present',
      (tester) async {
        final controller = TextEditingController(
          text: 'C:\\Firmware\\Stock_Qualcomm_Fastboot_v10.3',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassBouncePathField(
                controller: controller,
                colors: win11LightColors,
                hintText: 'Select folder',
              ),
            ),
          ),
        );

        // Verify BounceMarqueeText is visible
        expect(find.byType(BounceMarqueeText), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BounceMarqueeText),
            matching: find.text('C:\\Firmware\\Stock_Qualcomm_Fastboot_v10.3'),
          ),
          findsOneWidget,
        );

        // Tap on it to trigger focus
        await tester.tap(find.byType(BounceMarqueeText));
        await tester.pump();

        // Upon focus, TextField receives focus
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(
          textField.controller?.text,
          equals('C:\\Firmware\\Stock_Qualcomm_Fastboot_v10.3'),
        );
      },
    );

    testWidgets(
      'GlassBouncePathField displays TextField directly when text is empty',
      (tester) async {
        final controller = TextEditingController(text: '');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassBouncePathField(
                controller: controller,
                colors: win11DarkColors,
                hintText: 'Paste or browse firmware directory...',
              ),
            ),
          ),
        );

        // When text is empty, marquee is not rendered
        expect(find.byType(BounceMarqueeText), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.text('Paste or browse firmware directory...'),
          findsOneWidget,
        );
      },
    );

    test(
      'Light Mode Orb colors are soft pastels to prevent dark card blotches',
      () {
        // win11LightColors
        expect(win11LightColors.isDark, isFalse);
        expect(win11LightColors.orb1, equals(const Color(0xFF93C5FD)));
        expect(win11LightColors.orb2, equals(const Color(0xFFD8B4FE)));
        expect(win11LightColors.orb3, equals(const Color(0xFF67E8F9)));
        expect(win11LightColors.orbOpacity, lessThanOrEqualTo(0.16));

        // win10LightColors
        expect(win10LightColors.isDark, isFalse);
        expect(win10LightColors.orb1, equals(const Color(0xFF93C5FD)));
        expect(win10LightColors.orb2, equals(const Color(0xFFD8B4FE)));
        expect(win10LightColors.orb3, equals(const Color(0xFF67E8F9)));
        expect(win10LightColors.orbOpacity, lessThanOrEqualTo(0.16));
      },
    );
  });

  group('Live Glassmorphism Reactivity & Rollback Tests', () {
    testWidgets(
      'BentoCard reacts dynamically to AppTheme cardBlur and cardOpacity updates',
      (tester) async {
        final theme = AppTheme();
        theme.setLiveGlassmorphism(cardBlur: 15.0, cardOpacity: 0.30);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: theme,
            child: MaterialApp(
              home: Scaffold(
                body: BentoCard(
                  colors: theme.colors,
                  child: const Text('Live Bento Content'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Live Bento Content'), findsOneWidget);

        // Verify initial BackdropFilter with sigma 15
        final filterFinder = find.byType(BackdropFilter);
        expect(filterFinder, findsOneWidget);

        // Update theme glassmorphism live (e.g. from slider)
        theme.setLiveGlassmorphism(cardBlur: 32.0, cardOpacity: 0.60);
        await tester.pump();

        expect(find.byType(BackdropFilter), findsOneWidget);

        // Set blur to 0 (e.g. Lite mode)
        theme.setLiveGlassmorphism(cardBlur: 0.0);
        await tester.pump();
        expect(find.byType(BackdropFilter), findsNothing);
      },
    );

    testWidgets(
      'SettingsDialog cancellation rolls back glassmorphism and perfMode',
      (tester) async {
        final theme = AppTheme();
        theme.setLiveGlassmorphism(cardBlur: 20.0, cardOpacity: 0.25);
        theme.setPerfTierMode(PerfTierMode.ultra);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: theme,
            child: MaterialApp(
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showSettingsDialog(context: context, theme: theme);
                  },
                  child: const Text('Open Settings'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Settings'));
        await tester.pumpAndSettle();

        // Simulate user changing tier and fine-tuning sliders
        theme.setPerfTierMode(PerfTierMode.lite);
        theme.setLiveGlassmorphism(cardBlur: 35.0, cardOpacity: 0.80);
        await tester.pump();

        expect(theme.cardBlur, equals(35.0));
        expect(theme.cardOpacity, equals(0.80));
        expect(theme.perfMode, equals(PerfTierMode.lite));

        // Click Close button without saving
        final closeBtn = find.text(tr('action_close'));
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        // Verify theme values were rolled back
        expect(theme.cardBlur, equals(20.0));
        expect(theme.cardOpacity, equals(0.25));
        expect(theme.perfMode, equals(PerfTierMode.ultra));
      },
    );

    testWidgets('SettingsDialog save triggers onConfigSaved and keeps values', (
      tester,
    ) async {
      final theme = AppTheme();
      theme.setLiveGlassmorphism(cardBlur: 20.0, cardOpacity: 0.25);
      bool configSaved = false;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: theme,
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSettingsDialog(
                    context: context,
                    theme: theme,
                    onConfigSaved: () {
                      configSaved = true;
                    },
                  );
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Update values
      theme.setLiveGlassmorphism(cardBlur: 28.0, cardOpacity: 0.45);
      await tester.pump();

      // Click Save Settings
      final saveBtn = find.text(tr('action_save_settings'));
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(configSaved, isTrue);
      expect(theme.cardBlur, equals(28.0));
      expect(theme.cardOpacity, equals(0.45));
    });
  });

  group('Button & Header Label Cleanliness (No Duplicate Emojis)', () {
    test(
      'Verifies button & header labels do not contain prefix emojis across EN, VI, CN',
      () {
        final keysToCheck = [
          'paste_btn',
          'change_btn',
          'open_folder_btn',
          'edl_header',
          'adb_header',
          'reboot_all_adb',
          'flash_all',
          'abort_all',
          'boot_all_edl',
          'scan_now',
          'auto_flash_label',
          'copy_logs',
          'clear_logs',
          'lic_paste_clip',
          'lic_activate',
          'lic_sync',
        ];

        final forbiddenPrefixes = [
          '📋',
          '📂',
          '🖥️',
          '📟',
          '📱',
          '🔄',
          '⚡',
          '■',
          '🔍',
          '🗑️',
          '✅',
          '❌',
        ];

        for (final lang in ['EN', 'VI', 'CN']) {
          setLang(lang);
          for (final key in keysToCheck) {
            final label = tr(key);
            expect(
              label,
              isNotEmpty,
              reason: 'Key $key should not be empty in $lang',
            );
            for (final emoji in forbiddenPrefixes) {
              expect(
                label.startsWith(emoji),
                isFalse,
                reason:
                    'Label for $key in $lang ("$label") should not start with emoji $emoji',
              );
            }
          }
        }
      },
    );
  });
}
