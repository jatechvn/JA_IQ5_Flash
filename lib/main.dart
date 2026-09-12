// lib/main.dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:win32/win32.dart';

import 'modules/constants.dart';
import 'modules/ja_license_checker.dart';
import 'modules/utils.dart';
import 'modules/ui/styles.dart';
import 'modules/ui/main_window.dart';
import 'modules/ui/license_dialog.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.contains('-debug') ||
      args.contains('--debug') ||
      args.contains('-d')) {
    isCliDebug = true;
  }

  // Stop Qualcomm service on startup to enable Sahara packets capture
  await stopQualcommService();

  // Perform initial license validation
  final (licensed, _) = await checkLicenseSilent(appId);

  final theme = AppTheme();

  runApp(
    ChangeNotifierProvider.value(
      value: theme,
      child: MyApp(theme: theme, initiallyLicensed: licensed),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppTheme theme;
  final bool initiallyLicensed;

  const MyApp({
    super.key,
    required this.theme,
    required this.initiallyLicensed,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late bool _isLicensed;

  @override
  void initState() {
    super.initState();
    _isLicensed = widget.initiallyLicensed;
    WidgetsBinding.instance.addObserver(this);
    _updateNativeTitleBar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Re-enable service when app exits
      startQualcommService();
    }
  }

  void _updateNativeTitleBar() {
    if (!Platform.isWindows) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait briefly for Flutter window to create
      await Future.delayed(const Duration(milliseconds: 500));

      final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
      final windowName = appName.toNativeUtf16();
      try {
        final hwnd = FindWindow(className, windowName);
        if (hwnd != 0) {
          final pvAttribute = calloc<BOOL>()
            ..value = widget.theme.isDark ? TRUE : FALSE;
          DwmSetWindowAttribute(
            hwnd,
            DWMWA_USE_IMMERSIVE_DARK_MODE,
            pvAttribute,
            sizeOf<BOOL>(),
          );
          free(pvAttribute);
        }
      } finally {
        free(className);
        free(windowName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.theme,
      builder: (context, _) {
        _updateNativeTitleBar();
        return MaterialApp(
          title: appName,
          debugShowCheckedModeBanner: false,
          theme: widget.theme.themeData,
          home: _isLicensed
              ? MainWindow(theme: widget.theme)
              : Scaffold(
                  backgroundColor: widget.theme.scaffoldBg,
                  body: Center(
                    child: LicenseDialog(
                      theme: widget.theme,
                      exitOnFail: true,
                      onActivated: () {
                        setState(() {
                          _isLicensed = true;
                        });
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}
