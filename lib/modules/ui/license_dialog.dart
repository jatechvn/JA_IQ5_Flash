// lib/modules/ui/license_dialog.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../i18n.dart';
import '../ja_license_checker.dart';
import 'styles.dart';

class LicenseDialog extends StatefulWidget {
  final AppTheme theme;
  final bool exitOnFail;
  final VoidCallback? onActivated;

  const LicenseDialog({
    super.key,
    required this.theme,
    this.exitOnFail = true,
    this.onActivated,
  });

  @override
  State<LicenseDialog> createState() => _LicenseDialogState();
}

class _LicenseDialogState extends State<LicenseDialog> {
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
        backgroundColor: widget.theme.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipData != null && clipData.text != null) {
      _keyController.text = clipData.text!.trim();
    } else {
      setState(() {
        _statusMsg = tr('lic_clip_empty');
        _isSuccessMsg = false;
      });
    }
  }

  void _activateKey() {
    final keyStr = _keyController.text.trim();
    if (keyStr.isEmpty) {
      setState(() {
        _statusMsg = tr('lic_enter_first');
        _isSuccessMsg = false;
      });
      return;
    }

    final (ok, msg) = saveKey(keyStr, appId);
    setState(() {
      _statusMsg = msg;
      _isSuccessMsg = ok;
    });

    if (ok) {
      _refreshInfo();
      _keyController.clear();
      Future.delayed(const Duration(seconds: 1), () {
        if (widget.onActivated != null) {
          widget.onActivated!();
        } else if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    }
  }

  Future<void> _syncFromServer() async {
    setState(() {
      _isSyncing = true;
      _statusMsg = tr('lic_syncing');
      _isSuccessMsg = true;
    });

    final (ok, msg) = await forceSyncServer(appId);

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _statusMsg = msg;
        _isSuccessMsg = ok;
      });
      if (ok) {
        _refreshInfo();
        Future.delayed(const Duration(seconds: 1), () {
          if (widget.onActivated != null) {
            widget.onActivated!();
          } else if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final textTheme = t.themeData.textTheme;

    Color statusColor = t.danger;
    String statusText = _info.status;

    if (_info.valid && !_info.expired) {
      statusColor = t.success;
      statusText = tr('lic_valid');
    } else if (_info.expired) {
      statusColor = t.warning;
      statusText = tr('lic_expired');
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Dialog(
        backgroundColor: t.surfaceBg.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: t.borderTheme),
        ),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('lic_title'),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 12),

              // Expiry / Info
              if (_info.valid && !_info.expired) ...[
                Text(
                  tr('lic_days')
                      .replaceAll('{date}', _info.expiryDate ?? '')
                      .replaceAll('{days}', '${_info.daysRemaining}'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                tr('lic_contact'),
                style: textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 20),

              // Machine ID (HWID)
              Text(
                tr('lic_hwid_label'),
                style: textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: t.isDark ? Colors.black26 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.borderTheme),
                ),
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 4,
                  top: 4,
                  bottom: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _info.hwid,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: tr('lic_copy'),
                      icon: Icon(Icons.copy, size: 18, color: t.gradStart),
                      onPressed: _copyHwid,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Paste license key
              Text(
                tr('lic_key_label'),
                style: textTheme.titleMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _keyController,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: tr('lic_placeholder'),
                  hintStyle: TextStyle(color: t.textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: t.isDark ? Colors.black26 : Colors.black12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.borderTheme),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: t.gradStart),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),

              // Actions Row 1
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.paste, size: 16),
                      label: Text(tr('lic_paste_clip')),
                      onPressed: _pasteFromClipboard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.textPrimary,
                        side: BorderSide(color: t.borderTheme),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync, size: 16),
                      label: Text(tr('lic_sync')),
                      onPressed: _isSyncing ? null : _syncFromServer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.gradStart,
                        side: BorderSide(color: t.gradStart.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status message display
              if (_statusMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isSuccessMsg
                        ? t.success.withValues(alpha: 0.1)
                        : t.danger.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _isSuccessMsg
                          ? t.success.withValues(alpha: 0.3)
                          : t.danger.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMsg!,
                    style: TextStyle(
                      color: _isSuccessMsg ? t.success : t.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Actions Row 2 (Activate & Close/Exit)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_info.valid || _info.expired) ...[
                    TextButton(
                      child: Text(
                        tr('lic_exit'),
                        style: TextStyle(color: t.danger),
                      ),
                      onPressed: () => exit(0),
                    ),
                  ] else ...[
                    TextButton(
                      child: Text(
                        tr('lic_close'),
                        style: TextStyle(color: t.textSecondary),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _activateKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.gradEnd,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      tr('lic_activate'),
                      style: const TextStyle(
                        color: Colors.white,
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
    );
  }
}
