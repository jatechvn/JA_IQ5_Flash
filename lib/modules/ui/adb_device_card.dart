// lib/modules/ui/adb_device_card.dart
import 'package:flutter/material.dart';

import '../i18n.dart';
import '../logic/device_manager.dart';
import 'styles.dart';
import 'glass_widgets.dart';

class AdbDeviceCard extends StatelessWidget {
  final AdbDevice device;
  final AppTheme theme;
  final String status; // 'idle' | 'waiting' | 'success' | 'error' | 'fastboot'
  final bool autoFlashLocked;
  final void Function(String serial, bool isFastboot) onBootRequested;
  final void Function(String serial) onRemoveRequested;

  const AdbDeviceCard({
    super.key,
    required this.device,
    required this.theme,
    required this.status,
    required this.autoFlashLocked,
    required this.onBootRequested,
    required this.onRemoveRequested,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final c = t.colors;
    final isFastboot = device.isFastboot;

    final badgeLabel = isFastboot ? 'FASTBOOT' : 'ADB';
    final badgeColor = isFastboot ? c.accentPurple : c.accentCyan;

    // Map status states to icon and label color
    IconData statusIcon = isFastboot
        ? Icons.electrical_services_rounded
        : Icons.smartphone_rounded;
    Color statusLabelColor = c.textSecondary;
    String statusText = isFastboot
        ? tr('adb_fastboot_ready')
        : tr('adb_connected');
    Color? glow;

    if (status == 'waiting') {
      statusIcon = Icons.hourglass_top_rounded;
      statusLabelColor = c.accentAmber;
      statusText = tr('lic_syncing');
      glow = c.accentAmber;
    } else if (status == 'success') {
      statusIcon = Icons.check_circle_rounded;
      statusLabelColor = c.accentEmerald;
      statusText = tr('adb_switched_edl');
      glow = c.accentEmerald;
    } else if (status == 'error') {
      statusIcon = Icons.error_rounded;
      statusLabelColor = c.accentRose;
      statusText = tr('card_failed');
      glow = c.accentRose;
    }

    final isBusy = status == 'waiting';
    final isBtnEnabled = !isBusy && !autoFlashLocked;

    return BentoCard(
      colors: c,
      blurSigma: t.cardBlur,
      bgOpacity: t.cardOpacity,
      glowColor: glow,
      isFeatured: isBusy || status == 'success',
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: 230,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Mode Badge, Serial, Close Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.serial,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => onRemoveRequested(device.serial),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: c.subCardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.borderDefault),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.close, size: 10, color: c.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Model name if available
            if (device.model.isNotEmpty) ...[
              Text(
                device.model,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],

            // Status Row
            Row(
              children: [
                Icon(statusIcon, size: 13, color: statusLabelColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusLabelColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Boot to EDL Action Button
            SizedBox(
              width: double.infinity,
              height: 28,
              child: OutlinedButton.icon(
                onPressed: isBtnEnabled
                    ? () => onBootRequested(device.serial, isFastboot)
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isBtnEnabled ? badgeColor : c.textMuted,
                  side: BorderSide(
                    color: isBtnEnabled
                        ? badgeColor.withValues(alpha: 0.45)
                        : c.borderDefault,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  Icons.restart_alt,
                  size: 13,
                  color: isBtnEnabled ? badgeColor : c.textMuted,
                ),
                label: Text(
                  tr('adb_boot_to_edl'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isBtnEnabled ? c.textPrimary : c.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
