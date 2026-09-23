// lib/modules/ui/styles.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'app_colors.dart';

/// Performance Tier Mode for Graphic & Hardware Tuning
enum PerfTierMode {
  auto('auto', 'Auto'),
  ultra('ultra', 'Ultra'),
  balanced('balanced', 'Balanced'),
  lite('lite', 'Lite');

  final String id;
  final String label;
  const PerfTierMode(this.id, this.label);

  static PerfTierMode fromId(String? id) {
    if (id == null) return PerfTierMode.auto;
    return PerfTierMode.values.firstWhere(
      (m) => m.id.toLowerCase() == id.toLowerCase(),
      orElse: () => PerfTierMode.auto,
    );
  }
}

/// Effective Hardware Graphic Tier
enum HardwareTier {
  ultra('Ultra', '120 FPS • Max Glass', Icons.bolt_rounded, Color(0xFF0066FF)),
  balanced(
    'Balanced',
    '60 FPS • Laptop Opt',
    Icons.balance_rounded,
    Color(0xFF10B981),
  ),
  lite('Lite', 'Low Power • Zero Lag', Icons.eco_rounded, Color(0xFFF59E0B));

  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  const HardwareTier(this.label, this.desc, this.icon, this.color);
}

class AppTheme extends ChangeNotifier {
  String _themeMode = 'system';
  bool _isWin11 = false;

  // Performance & Graphic Tier Profiling
  PerfTierMode _perfMode = PerfTierMode.auto;
  late HardwareTier _detectedTier;
  int _cpuCores = 4;
  int _hardwareScore = 50;

  // Glassmorphism live tuning parameters (Matching JA_MES_Tool defaults)
  double _cardBlur = 20.0;
  double _cardOpacity = 0.25;
  double _dialogBlur = 20.0;
  double _dialogOpacity = 0.85;
  bool _enableMeshOrbs = true;
  double _meshOrbOpacity = 0.24;

  AppTheme({String initialMode = 'system'}) {
    _themeMode = initialMode;
    _detectWindowsVersion();
    _profileHardware();
  }

  PerfTierMode get perfMode => _perfMode;
  HardwareTier get detectedTier => _detectedTier;
  HardwareTier get effectiveTier {
    switch (_perfMode) {
      case PerfTierMode.auto:
        return _detectedTier;
      case PerfTierMode.ultra:
        return HardwareTier.ultra;
      case PerfTierMode.balanced:
        return HardwareTier.balanced;
      case PerfTierMode.lite:
        return HardwareTier.lite;
    }
  }

  String get perfLabel {
    if (_perfMode == PerfTierMode.auto) {
      return 'Auto (${effectiveTier.label})';
    }
    return _perfMode.label;
  }

  String get themeMode => _themeMode;

  bool get isDark {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  bool get isWin11 => _isWin11;

  double get cardBlur => _cardBlur;
  double get cardOpacity => _cardOpacity;
  double get dialogBlur => _dialogBlur;
  double get dialogOpacity => _dialogOpacity;
  bool get enableMeshOrbs => _enableMeshOrbs;
  double get meshOrbOpacity => _meshOrbOpacity;

  int get cpuCores => _cpuCores;
  int get hardwareScore => _hardwareScore;

  AppColors get colors {
    if (_isWin11) {
      return isDark ? win11DarkColors : win11LightColors;
    } else {
      return isDark ? win10DarkColors : win10LightColors;
    }
  }

  void _detectWindowsVersion() {
    if (!Platform.isWindows) return;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        _isWin11 = buildNumber >= 22000;
      }
    } catch (_) {}
  }

  void cyclePerfTier() {
    switch (_perfMode) {
      case PerfTierMode.auto:
        _perfMode = PerfTierMode.ultra;
        break;
      case PerfTierMode.ultra:
        _perfMode = PerfTierMode.balanced;
        break;
      case PerfTierMode.balanced:
        _perfMode = PerfTierMode.lite;
        break;
      case PerfTierMode.lite:
        _perfMode = PerfTierMode.auto;
        break;
    }
    _applyTierParameters(effectiveTier, notify: true);
  }

  void setPerfTierMode(PerfTierMode mode) {
    if (_perfMode != mode) {
      _perfMode = mode;
      _applyTierParameters(effectiveTier, notify: true);
    }
  }

  void _applyTierParameters(HardwareTier tier, {bool notify = true}) {
    switch (tier) {
      case HardwareTier.ultra:
        _cardBlur = 20.0;
        _cardOpacity = 0.25;
        _dialogBlur = 20.0;
        _dialogOpacity = 0.85;
        _enableMeshOrbs = true;
        _meshOrbOpacity = 0.24;
        break;
      case HardwareTier.balanced:
        _cardBlur = 14.0;
        _cardOpacity = 0.35;
        _dialogBlur = 16.0;
        _dialogOpacity = 0.90;
        _enableMeshOrbs = true;
        _meshOrbOpacity = 0.16;
        break;
      case HardwareTier.lite:
        _cardBlur = 0.0;
        _cardOpacity = 0.78;
        _dialogBlur = 8.0;
        _dialogOpacity = 0.95;
        _enableMeshOrbs = false;
        _meshOrbOpacity = 0.08;
        break;
    }
    if (notify) notifyListeners();
  }

  void _profileHardware() {
    try {
      _cpuCores = Platform.numberOfProcessors;
    } catch (_) {
      _cpuCores = 4;
    }

    int score = 50;
    if (_cpuCores >= 8) {
      score += 30;
    } else if (_cpuCores >= 4) {
      score += 10;
    } else {
      score -= 25;
    }

    if (_isWin11) score += 10;
    _hardwareScore = score.clamp(10, 100);

    if (_hardwareScore < 40) {
      _detectedTier = HardwareTier.lite;
    } else if (_hardwareScore < 70) {
      _detectedTier = HardwareTier.balanced;
    } else {
      _detectedTier = HardwareTier.ultra;
    }

    _applyTierParameters(effectiveTier, notify: false);
  }

  void setLiveGlassmorphism({
    double? cardBlur,
    double? cardOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    bool? enableMeshOrbs,
    double? meshOrbOpacity,
    bool notify = true,
  }) {
    if (cardBlur != null) _cardBlur = cardBlur.clamp(0.0, 40.0);
    if (cardOpacity != null) _cardOpacity = cardOpacity.clamp(0.05, 1.0);
    if (dialogBlur != null) _dialogBlur = dialogBlur.clamp(0.0, 40.0);
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity.clamp(0.1, 1.0);
    if (enableMeshOrbs != null) _enableMeshOrbs = enableMeshOrbs;
    if (meshOrbOpacity != null) {
      _meshOrbOpacity = meshOrbOpacity.clamp(0.05, 0.60);
    }
    if (notify) notifyListeners();
  }

  void resetGlassDefaults() {
    _perfMode = PerfTierMode.auto;
    _cardBlur = 20.0;
    _cardOpacity = 0.25;
    _dialogBlur = 20.0;
    _dialogOpacity = 0.85;
    _enableMeshOrbs = true;
    _meshOrbOpacity = 0.24;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = isDark ? 'light' : 'dark';
    notifyListeners();
  }

  void setThemeMode(String mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setTheme(bool dark) {
    final mode = dark ? 'dark' : 'light';
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // Theme Colors - mapped directly to AppColors design tokens
  Color get scaffoldBg => colors.bgPrimary;
  Color get surfaceBg => colors.headerBg;
  Color get cardBg => colors.cardBg;
  Color get cardBgSolid =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get borderTheme => colors.borderDefault;
  Color get shadowTheme => Colors.black.withValues(alpha: isDark ? 0.4 : 0.08);

  // Status & Brand Colors
  Color get gradStart => colors.accentCyan;
  Color get gradEnd => colors.accentColor;
  Color get accent => colors.accentEmerald;
  Color get warning => colors.accentAmber;
  Color get danger => colors.accentRose;
  Color get success => colors.accentEmerald;

  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: colors.accentColor,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: colors.cardBg,
      fontFamily: 'Outfit',
      dialogTheme: DialogThemeData(backgroundColor: colors.headerBg),
      dividerColor: colors.borderDefault,
      iconTheme: IconThemeData(color: colors.textPrimary),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontFamily: 'Outfit',
        ),
        bodyMedium: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
          fontFamily: 'Outfit',
        ),
        bodySmall: TextStyle(
          color: colors.textSecondary.withValues(alpha: 0.7),
          fontSize: 11,
          fontFamily: 'Outfit',
        ),
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Outfit',
        ),
        titleMedium: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          isDark ? Colors.white12 : Colors.black12,
        ),
        trackColor: WidgetStateProperty.all(Colors.transparent),
        radius: const Radius.circular(8),
      ),
    );
  }
}
