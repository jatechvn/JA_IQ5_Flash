import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../constants.dart';
import 'firmware_preflight.dart';
import '../i18n.dart';

enum FirmwareSlotType {
  factory(
    'factory',
    'FACTORY ROM',
    Color(0xFF38BDF8),
    Icons.precision_manufacturing_rounded,
  ),
  user('user', 'USER ROM', Color(0xFF34D399), Icons.perm_identity_rounded),
  diag('diag', 'DIAG / TEST', Color(0xFFFBBF24), Icons.build_circle_rounded);

  final String id;
  final String badge;
  final Color color;
  final IconData icon;

  const FirmwareSlotType(this.id, this.badge, this.color, this.icon);

  String get localizedBadge {
    switch (this) {
      case FirmwareSlotType.factory:
        return tr('badge_factory');
      case FirmwareSlotType.user:
        return tr('badge_user');
      case FirmwareSlotType.diag:
        return tr('badge_diag');
    }
  }

  static FirmwareSlotType fromId(String id) {
    switch (id) {
      case 'user':
        return FirmwareSlotType.user;
      case 'diag':
        return FirmwareSlotType.diag;
      case 'factory':
      default:
        return FirmwareSlotType.factory;
    }
  }
}

class FirmwareValidationResult {
  final bool isValid;
  final String statusKey; // 'fw_ok' | 'fw_missing' | 'fw_invalid' | 'fw_empty'
  final String? detectedFirehose;
  final int xmlCount;
  final List<String> missingFiles;
  final String detailMessage;

  const FirmwareValidationResult({
    required this.isValid,
    required this.statusKey,
    this.detectedFirehose,
    this.xmlCount = 0,
    this.missingFiles = const [],
    required this.detailMessage,
  });

  String get localizedMessage {
    switch (statusKey) {
      case 'fw_empty':
        return tr('fw_no_folder_selected');
      case 'fw_invalid':
        return tr('fw_dir_not_exist');
      case 'fw_missing':
        final prefix = tr('fw_missing_files');
        return '$prefix: ${missingFiles.join(', ')}';
      case 'fw_ok':
        final xmlLabel = tr('fw_files_count').replaceAll('{xml}', '$xmlCount');
        return '$detectedFirehose • $xmlLabel';
      default:
        return detailMessage;
    }
  }
}

class FirmwareSlotProfile {
  final int index; // 0, 1, 2 (User displays: Slot 1, Slot 2, Slot 3)
  FirmwareSlotType type;
  String customName;
  String path;
  FirmwareValidationResult lastValidation;

  FirmwareSlotProfile({
    required this.index,
    required this.type,
    required this.customName,
    required this.path,
    this.lastValidation = const FirmwareValidationResult(
      isValid: false,
      statusKey: 'fw_empty',
      detailMessage: 'Chưa cấu hình đường dẫn',
    ),
  });

  static bool isDefaultSlotName(String name) {
    if (name.trim().isEmpty) return true;
    const defaultNames = {
      // English
      'Factory Stock ROM', 'User / Custom ROM', 'Diag / Test ROM',
      'User Custom ROM', 'Diag Test ROM', 'Test Slot',
      'Factory ROM', 'User ROM', 'Diag ROM',
      // Vietnamese
      'Bản ROM Chuẩn Nhà Máy',
      'Bản ROM Khách Hàng / Tuỳ Biến',
      'Bản ROM Kỹ Thuật / Chẩn Đoán',
      // Chinese
      '原厂官方固件', '客户定制固件', '工程测试固件',
      // Badges
      'FACTORY ROM', 'USER ROM', 'DIAG / TEST',
    };
    return defaultNames.contains(name.trim());
  }

  String get displayName {
    if (customName.isNotEmpty && !isDefaultSlotName(customName)) {
      return customName;
    }
    switch (type) {
      case FirmwareSlotType.factory:
        return tr('slot_factory_rom');
      case FirmwareSlotType.user:
        return tr('slot_user_rom');
      case FirmwareSlotType.diag:
        return tr('slot_diag_rom');
    }
  }

  String get defaultDescription {
    switch (type) {
      case FirmwareSlotType.factory:
        return tr('slot_desc_factory');
      case FirmwareSlotType.user:
        return tr('slot_desc_user');
      case FirmwareSlotType.diag:
        return tr('slot_desc_diag');
    }
  }

  /// Run detailed check on directory content for Qualcomm flash requirements
  FirmwareValidationResult validate({bool deep = true}) {
    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      lastValidation = const FirmwareValidationResult(
        isValid: false,
        statusKey: 'fw_empty',
        detailMessage: 'Chưa chọn thư mục',
      );
      return lastValidation;
    }

    final dir = Directory(trimmedPath);
    if (!dir.existsSync()) {
      lastValidation = const FirmwareValidationResult(
        isValid: false,
        statusKey: 'fw_invalid',
        detailMessage: 'Thư mục không tồn tại',
      );
      return lastValidation;
    }

    // 1. Check exact required files from constants
    final rawXml = File(p.join(trimmedPath, rawprogramXml));
    final patXml = File(p.join(trimmedPath, patchXml));
    final elf = File(p.join(trimmedPath, firehoseElf));

    List<String> missing = [];
    String? foundFirehose;
    int xmls = 0;

    if (elf.existsSync()) {
      foundFirehose = firehoseElf;
    } else {
      // Match the programmer required by QfilEngine and RebootWorker.
      missing.add(firehoseElf);
    }

    if (rawXml.existsSync()) {
      xmls++;
    } else {
      missing.add(rawprogramXml);
    }

    if (patXml.existsSync()) {
      xmls++;
    } else {
      missing.add(patchXml);
    }

    if (deep && missing.isEmpty) {
      final errors = validateFirmware(trimmedPath);
      if (errors.isNotEmpty) {
        lastValidation = FirmwareValidationResult(
          isValid: false,
          statusKey: 'fw_content_invalid',
          detailMessage: errors.join('\n'),
        );
        return lastValidation;
      }
    }
    final bool ok = missing.isEmpty;
    String msg;
    if (ok) {
      msg = '$foundFirehose • $xmls file XML';
    } else {
      msg = 'Thiếu: ${missing.join(', ')}';
    }

    lastValidation = FirmwareValidationResult(
      isValid: ok,
      statusKey: ok ? 'fw_ok' : 'fw_missing',
      detectedFirehose: foundFirehose,
      xmlCount: xmls,
      missingFiles: missing,
      detailMessage: msg,
    );

    return lastValidation;
  }
}

Future<FirmwareValidationResult> validateFirmwareSlot(String directory) =>
    Isolate.run(
      () => FirmwareSlotProfile(
        index: 0,
        type: FirmwareSlotType.factory,
        customName: '',
        path: directory,
      ).validate(),
    );
