// lib/modules/ui/settings_dialog.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../i18n.dart';
import '../ja_license_checker.dart';
import 'app_colors.dart';
import 'glass_widgets.dart';
import 'styles.dart';

/// Show the comprehensive Glassmorphic Settings modal.
Future<bool?> showSettingsDialog({
  required BuildContext context,
  required AppTheme theme,
  int initialTab = 0,
  VoidCallback? onConfigSaved,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => _SettingsDialogContent(
      theme: theme,
      initialTab: initialTab,
      onConfigSaved: onConfigSaved,
    ),
  );
}

class _SettingsDialogContent extends StatefulWidget {
  final AppTheme theme;
  final int initialTab;
  final VoidCallback? onConfigSaved;

  const _SettingsDialogContent({
    required this.theme,
    required this.initialTab,
    this.onConfigSaved,
  });

  @override
  State<_SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<_SettingsDialogContent> {
  late int _activeTab;

  // Local copy of live tuning values
  late double _cardBlur;
  late double _cardOpacity;
  late double _dialogBlur;
  late double _dialogOpacity;
  late bool _enableMeshOrbs;
  late double _meshOrbOpacity;

  // Original tuning values for cancellation rollback (matching JA_MES_Tool)
  late final double _origCardBlur;
  late final double _origCardOpacity;
  late final double _origDialogBlur;
  late final double _origDialogOpacity;
  late final bool _origEnableMeshOrbs;
  late final double _origMeshOrbOpacity;
  late final PerfTierMode _origPerfMode;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 3);
    final t = widget.theme;
    _origCardBlur = t.cardBlur;
    _origCardOpacity = t.cardOpacity;
    _origDialogBlur = t.dialogBlur;
    _origDialogOpacity = t.dialogOpacity;
    _origEnableMeshOrbs = t.enableMeshOrbs;
    _origMeshOrbOpacity = t.meshOrbOpacity;
    _origPerfMode = t.perfMode;

    _cardBlur = _origCardBlur;
    _cardOpacity = _origCardOpacity;
    _dialogBlur = _origDialogBlur;
    _dialogOpacity = _origDialogOpacity;
    _enableMeshOrbs = _origEnableMeshOrbs;
    _meshOrbOpacity = _origMeshOrbOpacity;
  }

  void _rollbackAndClose() {
    widget.theme.setLiveGlassmorphism(
      cardBlur: _origCardBlur,
      cardOpacity: _origCardOpacity,
      dialogBlur: _origDialogBlur,
      dialogOpacity: _origDialogOpacity,
      enableMeshOrbs: _origEnableMeshOrbs,
      meshOrbOpacity: _origMeshOrbOpacity,
    );
    widget.theme.setPerfTierMode(_origPerfMode);
    Navigator.pop(context, false);
  }

  void _resetDefaults() {
    setState(() {
      widget.theme.resetGlassDefaults();
      _cardBlur = widget.theme.cardBlur;
      _cardOpacity = widget.theme.cardOpacity;
      _dialogBlur = widget.theme.dialogBlur;
      _dialogOpacity = widget.theme.dialogOpacity;
      _enableMeshOrbs = widget.theme.enableMeshOrbs;
      _meshOrbOpacity = widget.theme.meshOrbOpacity;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final c = t.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _rollbackAndClose();
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _dialogBlur, sigmaY: _dialogBlur),
        child: Dialog(
          backgroundColor: c.headerBg.withValues(alpha: _dialogOpacity),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: c.borderDefault, width: 1.2),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Container(
          width: 660,
          height: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Top Header ───────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.accentCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: c.accentCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 20,
                      color: c.accentCyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('settings_title'),
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$appName • v$appVersion',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: c.textSecondary,
                    onPressed: _rollbackAndClose,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── 2. Pill Tab Selector ────────────────────────────────────
              _SettingsTabSelector(
                activeTab: _activeTab,
                colors: c,
                onTabSelected: (index) => setState(() => _activeTab = index),
              ),
              const SizedBox(height: 10),

              // ── 3. Tab Body ─────────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildActiveTab(c, t),
                ),
              ),
              const SizedBox(height: 14),

              // ── 4. Action Footer ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _rollbackAndClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      tr('action_close'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onConfigSaved != null) {
                        widget.onConfigSaved!();
                      }
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      tr('action_save_settings'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _onPerfTierChanged(PerfTierMode mode) {
    setState(() {
      widget.theme.setPerfTierMode(mode);
      _cardBlur = widget.theme.cardBlur;
      _cardOpacity = widget.theme.cardOpacity;
      _dialogBlur = widget.theme.dialogBlur;
      _dialogOpacity = widget.theme.dialogOpacity;
      _enableMeshOrbs = widget.theme.enableMeshOrbs;
      _meshOrbOpacity = widget.theme.meshOrbOpacity;
    });
  }

  Widget _buildActiveTab(AppColors c, AppTheme t) {
    switch (_activeTab) {
      case 0:
        return _SettingsGlassTuningTab(
          colors: c,
          theme: t,
          cardBlur: _cardBlur,
          cardOpacity: _cardOpacity,
          dialogBlur: _dialogBlur,
          dialogOpacity: _dialogOpacity,
          enableMeshOrbs: _enableMeshOrbs,
          meshOrbOpacity: _meshOrbOpacity,
          onPerfTierChanged: _onPerfTierChanged,
          onCardBlurChanged: (v) {
            setState(() => _cardBlur = v);
            t.setLiveGlassmorphism(cardBlur: v);
          },
          onCardOpacityChanged: (v) {
            setState(() => _cardOpacity = v);
            t.setLiveGlassmorphism(cardOpacity: v);
          },
          onDialogBlurChanged: (v) {
            setState(() => _dialogBlur = v);
            t.setLiveGlassmorphism(dialogBlur: v);
          },
          onDialogOpacityChanged: (v) {
            setState(() => _dialogOpacity = v);
            t.setLiveGlassmorphism(dialogOpacity: v);
          },
          onMeshOrbsToggled: (v) {
            setState(() => _enableMeshOrbs = v);
            t.setLiveGlassmorphism(enableMeshOrbs: v);
          },
          onMeshOrbOpacityChanged: (v) {
            setState(() => _meshOrbOpacity = v);
            t.setLiveGlassmorphism(meshOrbOpacity: v);
          },
          onResetDefaults: _resetDefaults,
        );
      case 1:
        return _SettingsUserGuideTab(colors: c);
      case 2:
        return _SettingsAboutTab(colors: c, theme: t);
      case 3:
      default:
        return _SettingsLicenseTab(colors: c, theme: t);
    }
  }
}

// ── Tab Selector ────────────────────────────────────────────────────────────

class _SettingsTabSelector extends StatelessWidget {
  final int activeTab;
  final AppColors colors;
  final ValueChanged<int> onTabSelected;

  const _SettingsTabSelector({
    required this.activeTab,
    required this.colors,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        children: [
          _buildItem(0, Icons.tune_rounded, tr('tab_glass')),
          _buildItem(1, Icons.menu_book_rounded, tr('tab_guide')),
          _buildItem(2, Icons.info_outline_rounded, tr('tab_about')),
          _buildItem(3, Icons.vpn_key_rounded, tr('tab_license')),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isSelected = activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colors.accentColor,
                      colors.accentCyan.withValues(alpha: 0.85),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab 1: Glass Tuning ─────────────────────────────────────────────────────

class _SettingsGlassTuningTab extends StatelessWidget {
  final AppColors colors;
  final AppTheme? theme;
  final double cardBlur;
  final double cardOpacity;
  final double dialogBlur;
  final double dialogOpacity;
  final bool enableMeshOrbs;
  final double meshOrbOpacity;
  final ValueChanged<PerfTierMode>? onPerfTierChanged;
  final ValueChanged<double> onCardBlurChanged;
  final ValueChanged<double> onCardOpacityChanged;
  final ValueChanged<double> onDialogBlurChanged;
  final ValueChanged<double> onDialogOpacityChanged;
  final ValueChanged<bool> onMeshOrbsToggled;
  final ValueChanged<double> onMeshOrbOpacityChanged;
  final VoidCallback onResetDefaults;

  const _SettingsGlassTuningTab({
    required this.colors,
    this.theme,
    required this.cardBlur,
    required this.cardOpacity,
    required this.dialogBlur,
    required this.dialogOpacity,
    required this.enableMeshOrbs,
    required this.meshOrbOpacity,
    this.onPerfTierChanged,
    required this.onCardBlurChanged,
    required this.onCardOpacityChanged,
    required this.onDialogBlurChanged,
    required this.onDialogOpacityChanged,
    required this.onMeshOrbsToggled,
    required this.onMeshOrbOpacityChanged,
    required this.onResetDefaults,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.subCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.subCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.blur_on_rounded,
                      size: 18,
                      color: colors.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tr('settings_glass_header'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: onResetDefaults,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      tr('settings_default'),
                      style: TextStyle(
                        color: colors.accentCyan,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hardware Profiling & Graphic Performance Tier Section
            if (theme != null) ...[
              _buildHardwareProfileSection(context),
              const SizedBox(height: 12),
              Divider(color: colors.subCardBorder, height: 1),
              const SizedBox(height: 12),
            ],

            // Card Blur & Opacity
            _SettingsSlider(
              label: tr('settings_card_blur'),
              value: cardBlur,
              min: 0,
              max: 40,
              colors: colors,
              onChanged: onCardBlurChanged,
            ),
            _SettingsSlider(
              label: tr('settings_card_opacity'),
              value: cardOpacity,
              min: 0.05,
              max: 1.0,
              isPercent: true,
              colors: colors,
              onChanged: onCardOpacityChanged,
            ),
            const SizedBox(height: 4),
            Divider(color: colors.subCardBorder, height: 1),
            const SizedBox(height: 4),

            // Dialog Blur & Opacity
            _SettingsSlider(
              label: tr('settings_dialog_blur'),
              value: dialogBlur,
              min: 0,
              max: 40,
              colors: colors,
              onChanged: onDialogBlurChanged,
            ),
            _SettingsSlider(
              label: tr('settings_dialog_opacity'),
              value: dialogOpacity,
              min: 0.10,
              max: 1.0,
              isPercent: true,
              colors: colors,
              onChanged: onDialogOpacityChanged,
            ),
            const SizedBox(height: 4),
            Divider(color: colors.subCardBorder, height: 1),
            const SizedBox(height: 8),

            // Mesh Orbs Toggle Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('settings_mesh_orbs'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('settings_mesh_orbs_sub'),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enableMeshOrbs,
                  activeThumbColor: colors.accentCyan,
                  onChanged: onMeshOrbsToggled,
                ),
              ],
            ),
            if (enableMeshOrbs) ...[
              const SizedBox(height: 4),
              _SettingsSlider(
                label: tr('settings_mesh_opacity'),
                value: meshOrbOpacity,
                min: 0.05,
                max: 0.60,
                isPercent: true,
                colors: colors,
                onChanged: onMeshOrbOpacityChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareProfileSection(BuildContext context) {
    final t = theme!;
    final tier = t.effectiveTier;
    final detected = t.detectedTier;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.headerBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Detected Badge
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tier.color.withValues(alpha: 0.35)),
                ),
                child: Icon(tier.icon, color: tier.color, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('perf_tier_header'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${tr('perf_detected_label')} ${detected.label} • ${t.cpuCores} Cores • ${tr('perf_score_label')} ${t.hardwareScore}/100',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              PillBadge(
                label: t.perfLabel,
                color: tier.color,
                bg: tier.color.withValues(alpha: 0.15),
                border: tier.color.withValues(alpha: 0.35),
                fontSize: 9.5,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4-Mode Selector (Auto, Ultra, Balanced, Lite)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Row(
              children: [
                _buildModeItem(PerfTierMode.auto, tr('perf_auto'), Icons.auto_mode_rounded),
                _buildModeItem(PerfTierMode.ultra, tr('perf_ultra'), Icons.bolt_rounded),
                _buildModeItem(PerfTierMode.balanced, tr('perf_balanced'), Icons.balance_rounded),
                _buildModeItem(PerfTierMode.lite, tr('perf_lite'), Icons.eco_rounded),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dynamic Description
          Text(
            _getModeDescription(t.perfMode),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeItem(PerfTierMode mode, String label, IconData icon) {
    final isSelected = theme!.perfMode == mode;
    final color = isSelected ? colors.accentCyan : colors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (onPerfTierChanged != null) {
            onPerfTierChanged!(mode);
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accentCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: colors.accentCyan.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? colors.textPrimary : colors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModeDescription(PerfTierMode mode) {
    switch (mode) {
      case PerfTierMode.auto:
        return tr('perf_desc_auto');
      case PerfTierMode.ultra:
        return tr('perf_desc_ultra');
      case PerfTierMode.balanced:
        return tr('perf_desc_balanced');
      case PerfTierMode.lite:
        return tr('perf_desc_lite');
    }
  }
}

class _SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final bool isPercent;
  final AppColors colors;
  final ValueChanged<double> onChanged;

  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.isPercent = false,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final display = isPercent
        ? '${(value * 100).round()}%'
        : '${value.toStringAsFixed(0)} px';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                display,
                style: TextStyle(
                  color: colors.accentCyan,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: colors.accentColor,
              inactiveTrackColor: colors.subCardBorder,
              thumbColor: colors.accentCyan,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: isPercent ? 20 : 40,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: User Guide ───────────────────────────────────────────────────────

class _SettingsUserGuideTab extends StatelessWidget {
  final AppColors colors;

  const _SettingsUserGuideTab({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            icon: Icons.flash_on_rounded,
            accent: colors.accentCyan,
            title: tr('guide_flash_title'),
            desc: tr('guide_flash_desc'),
          ),
          const SizedBox(height: 8),
          _buildCard(
            icon: Icons.autorenew_rounded,
            accent: colors.accentEmerald,
            title: tr('guide_autoflash_title'),
            desc: tr('guide_autoflash_desc'),
          ),
          const SizedBox(height: 8),
          _buildCard(
            icon: Icons.layers_rounded,
            accent: colors.accentAmber,
            title: tr('guide_slots_title'),
            desc: tr('guide_slots_desc'),
          ),
          const SizedBox(height: 8),
          _buildCard(
            icon: Icons.lightbulb_rounded,
            accent: colors.accentPurple,
            title: tr('guide_trouble_title'),
            desc: tr('guide_trouble_desc'),
          ),
          const SizedBox(height: 8),
          _buildCard(
            icon: Icons.auto_awesome_rounded,
            accent: colors.accentCyan,
            title: tr('guide_glass_title'),
            desc: tr('guide_glass_desc'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color accent,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 3: About ────────────────────────────────────────────────────────────

class _SettingsAboutTab extends StatelessWidget {
  final AppColors colors;
  final AppTheme theme;

  const _SettingsAboutTab({required this.colors, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.accentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.accentColor, colors.accentCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryGlow.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'JA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            tr('about_app_name'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          PillBadge(
                            label: isCliDebug ? 'DEBUG' : 'RELEASE',
                            color: isCliDebug
                                ? colors.accentAmber
                                : colors.accentEmerald,
                            bg: (isCliDebug
                                    ? colors.accentAmber
                                    : colors.accentEmerald)
                                .withValues(alpha: 0.15),
                            border: (isCliDebug
                                    ? colors.accentAmber
                                    : colors.accentEmerald)
                                .withValues(alpha: 0.4),
                            fontSize: 9.5,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'v$appVersion • Build (${getBuildTime()})',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('about_app_desc'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),

          // System Runtime Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('about_sys_title'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  tr('about_os_label'),
                  Platform.operatingSystemVersion,
                ),
                _buildInfoRow(
                  tr('about_cpu_label'),
                  '${theme.cpuCores} Cores',
                ),
                _buildInfoRow(
                  tr('about_score_label'),
                  '${theme.hardwareScore}/100',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Developer & License Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('about_dev_title'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildInfoRow(
                  'Tác giả / Author',
                  tr('about_author'),
                ),
                _buildInfoRow(
                  'Bản quyền / License',
                  'Commercial Internal Tool (JA Tech)',
                ),
                _buildInfoRow(
                  'Kiến trúc',
                  tr('about_blueprint'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 4: License ──────────────────────────────────────────────────────────

class _SettingsLicenseTab extends StatefulWidget {
  final AppColors colors;
  final AppTheme theme;

  const _SettingsLicenseTab({required this.colors, required this.theme});

  @override
  State<_SettingsLicenseTab> createState() => _SettingsLicenseTabState();
}

class _SettingsLicenseTabState extends State<_SettingsLicenseTab> {
  final TextEditingController _keyController = TextEditingController();
  late LicenseInfo _info;
  bool _isSyncing = false;
  String? _statusMsg;
  bool _isSuccessMsg = false;

  @override
  void initState() {
    super.initState();
    _refreshInfo();
  }

  void _refreshInfo() {
    setState(() {
      _info = getLicenseInfo(appId);
    });
  }

  void _copyHwid() {
    Clipboard.setData(ClipboardData(text: _info.hwid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('lic_copied')),
        backgroundColor: widget.colors.accentEmerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipData != null && clipData.text != null) {
      _keyController.text = clipData.text!.trim();
    }
  }

  void _activateKey() {
    final keyStr = _keyController.text.trim();
    if (keyStr.isEmpty) return;

    final (ok, msg) = saveKey(keyStr, appId);
    setState(() {
      _statusMsg = msg;
      _isSuccessMsg = ok;
    });

    if (ok) {
      _refreshInfo();
      _keyController.clear();
    }
  }

  Future<void> _syncFromServer() async {
    setState(() {
      _isSyncing = true;
      _statusMsg = null;
    });

    final (ok, msg) = await forceSyncServer(appId);
    if (!mounted) return;

    setState(() {
      _isSyncing = false;
      _statusMsg = msg;
      _isSuccessMsg = ok;
    });

    if (ok) {
      _refreshInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final isValid = _info.valid && !_info.expired;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // License Status Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.subCardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isValid ? c.accentEmerald : c.accentRose)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                  color: isValid ? c.accentEmerald : c.accentRose,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            tr('lic_status_label'),
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          PillBadge(
                            label: isValid ? tr('lic_valid') : tr('lic_invalid'),
                            color: isValid ? c.accentEmerald : c.accentRose,
                            bg: (isValid ? c.accentEmerald : c.accentRose)
                                .withValues(alpha: 0.15),
                            border: (isValid ? c.accentEmerald : c.accentRose)
                                .withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isValid
                            ? tr('lic_days_left').replaceAll(
                                '{days}',
                                '${_info.daysRemaining}',
                              )
                            : (_info.error ?? tr('lic_expired')),
                        style: TextStyle(
                          color: isValid ? c.textPrimary : c.accentRose,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // LAN Sync Button
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _syncFromServer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accentCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 14),
                  label: Text(
                    tr('lic_sync_lan_btn'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // HWID Machine Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('lic_hwid_label'),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: c.headerBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: c.borderDefault),
                        ),
                        child: Text(
                          _info.hwid,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: c.accentCyan,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _copyHwid,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.borderDefault),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 13),
                      label: Text(
                        tr('lic_copy_hwid_btn'),
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Manual Key Activation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.subCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.subCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('lic_manual_activate_header'),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _keyController,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: c.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: tr('lic_key_input_hint'),
                    hintStyle: TextStyle(fontSize: 11, color: c.textMuted),
                    filled: true,
                    fillColor: c.headerBg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.borderDefault),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.borderDefault),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.accentCyan, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pasteFromClipboard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.textPrimary,
                        side: BorderSide(color: c.borderDefault),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.paste_rounded, size: 13),
                      label: Text(
                        tr('lic_paste_btn'),
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _activateKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accentEmerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
                      label: Text(
                        tr('lic_activate_now_btn'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_statusMsg != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (_isSuccessMsg ? c.accentEmerald : c.accentRose)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (_isSuccessMsg ? c.accentEmerald : c.accentRose)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _statusMsg!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isSuccessMsg ? c.accentEmerald : c.accentRose,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}