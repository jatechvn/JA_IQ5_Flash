// lib/modules/ui/device_card.dart
import 'package:flutter/material.dart';

import '../i18n.dart';
import '../logic/flash_session.dart';
import 'styles.dart';
import 'glass_widgets.dart';

class DeviceCard extends StatefulWidget {
  final FlashSession session;
  final AppTheme theme;
  final bool autoFlashLocked;
  final void Function(String port) onFlashRequested;
  final void Function(String port) onAbortRequested;
  final void Function(String port) onRemoveRequested;
  final void Function(String port) onRebootRequested;

  const DeviceCard({
    super.key,
    required this.session,
    required this.theme,
    required this.autoFlashLocked,
    required this.onFlashRequested,
    required this.onAbortRequested,
    required this.onRemoveRequested,
    required this.onRebootRequested,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final c = t.colors;

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final status = session.status;
        final progress = session.progress;

        // Auto scroll logs to bottom
        if (session.logs.isNotEmpty && _logScrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_logScrollController.hasClients) {
              _logScrollController.jumpTo(
                _logScrollController.position.maxScrollExtent,
              );
            }
          });
        }

        // Map status to icon, colors and labels
        IconData statusIcon = Icons.developer_board_rounded;
        Color statusColor = c.accentCyan;
        String statusLabel = tr('card_edl_ready');
        Color? glow;

        if (status == FlashSession.statusRunning) {
          statusIcon = Icons.bolt_rounded;
          statusColor = c.accentCyan;
          statusLabel = '${tr('card_flashing')} $progress%';
          glow = c.accentCyan;
        } else if (status == FlashSession.statusSuccess) {
          statusIcon = Icons.check_circle_rounded;
          statusColor = c.accentEmerald;
          statusLabel = tr('card_completed');
          glow = c.accentEmerald;
        } else if (status == FlashSession.statusError) {
          statusIcon = Icons.error_rounded;
          statusColor = c.accentRose;
          statusLabel = tr('card_failed');
          glow = c.accentRose;
        } else if (status == FlashSession.statusAborted) {
          statusIcon = Icons.cancel_rounded;
          statusColor = c.accentAmber;
          statusLabel = tr('card_aborted');
          glow = c.accentAmber;
        } else if (status == 'rebooting') {
          statusIcon = Icons.restart_alt_rounded;
          statusColor = c.accentAmber;
          statusLabel = tr('card_rebooting');
          glow = c.accentAmber;
        }

        final isBusy =
            status == FlashSession.statusRunning || status == 'rebooting';
        final isManualDisabled = widget.autoFlashLocked || isBusy;

        return BentoCard(
          colors: c,
          blurSigma: t.cardBlur,
          bgOpacity: t.cardOpacity,
          glowColor: glow,
          isFeatured: isBusy || status == FlashSession.statusSuccess,
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 295,
            height: 205,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row (Icon, Port Name, Status Badge, Remove Button)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                session.port,
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: c.subCardBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: c.subCardBorder),
                                ),
                                child: Text(
                                  '9008',
                                  style: TextStyle(
                                    color: c.accentCyan,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Qualcomm HS-USB QDLoader',
                            style: TextStyle(
                              color: c.textSecondary.withValues(alpha: 0.7),
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PillBadge(
                      label: statusLabel,
                      color: statusColor,
                      bg: statusColor.withValues(alpha: 0.12),
                      border: statusColor.withValues(alpha: 0.3),
                      showDot: isBusy || status == FlashSession.statusSuccess,
                      fontSize: 9.5,
                    ),
                    if (!widget.autoFlashLocked) ...[
                      const SizedBox(width: 5),
                      InkWell(
                        onTap: () => widget.onRemoveRequested(session.port),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.subCardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.borderDefault),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close,
                            size: 11,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Progress Bar with Percentage Tag
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: progress / 100.0,
                            backgroundColor: c.subCardBg,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              status == FlashSession.statusSuccess
                                  ? c.accentEmerald
                                  : status == FlashSession.statusError
                                  ? c.accentRose
                                  : c.accentCyan,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$progress%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Mini Glass Console
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: c.subCardBg,
                      border: Border.all(color: c.subCardBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Scrollbar(
                      controller: _logScrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _logScrollController,
                        child: SelectableText(
                          session.logs.isEmpty
                              ? tr('card_waiting_cmd')
                              : session.logs.join('\n'),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 9.5,
                            color: t.isDark
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFF047857),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Action Controls (Flash, Abort, Reboot)
                Row(
                  children: [
                    // Flash Button
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton.icon(
                          onPressed: isManualDisabled
                              ? null
                              : () => widget.onFlashRequested(session.port),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isManualDisabled
                                ? c.subCardBg
                                : c.accentColor,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: c.textMuted,
                            disabledBackgroundColor: c.subCardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(
                            Icons.flash_on,
                            size: 13,
                            color: isManualDisabled ? c.textMuted : Colors.white,
                          ),
                          label: Text(
                            tr('card_flash_btn'),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),

                    // Abort Button
                    if (status == FlashSession.statusRunning) ...[
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 28,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                widget.onAbortRequested(session.port),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accentRose,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.stop, size: 13),
                            label: Text(
                              tr('card_abort_btn'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],

                    // Reboot to ADB Button
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: isManualDisabled
                              ? null
                              : () => widget.onRebootRequested(session.port),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.textPrimary,
                            side: BorderSide(
                              color: isManualDisabled
                                  ? c.borderDefault
                                  : c.accentAmber.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(
                            Icons.cached,
                            size: 13,
                            color: isManualDisabled
                                ? c.textMuted
                                : c.accentAmber,
                          ),
                          label: Text(
                            tr('card_reboot_adb_btn'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isManualDisabled
                                  ? c.textMuted
                                  : c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
