// lib/modules/ja_license_checker.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

const String _defaultServerPath =
    r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_key\{APP_ID}.key';
const String _defaultSecret = 'JohnAlaaSecretKey_2026!@#';
const String _sep = '|';
const String _innerSep = ':';
const String _shareHost = r'\\10.81.141.226\temp';
const String _shareUser = 'user';
const String _sharePass = 'user';

class LicenseInfo {
  final String status;
  final String appId;
  final String? expiryDate;
  final int daysRemaining;
  final bool valid;
  final bool expired;
  final String? error;
  final String hwid;

  LicenseInfo({
    required this.status,
    required this.appId,
    this.expiryDate,
    required this.daysRemaining,
    required this.valid,
    required this.expired,
    this.error,
    required this.hwid,
  });
}

/// Mount network share with credentials.
Future<bool> mountShare() async {
  if (!Platform.isWindows) return false;
  try {
    final result = await Process.run('net', [
      'use',
      _shareHost,
      '/user:$_shareUser',
      _sharePass,
      '/persistent:no',
    ], runInShell: true);
    final output = '${result.stdout}${result.stderr}';
    if (result.exitCode == 0 || output.toLowerCase().contains('already')) {
      return true;
    }
  } catch (_) {}
  return false;
}

/// Unmount network share.
Future<void> unmountShare() async {
  if (!Platform.isWindows) return;
  try {
    await Process.run('net', [
      'use',
      _shareHost,
      '/delete',
      '/yes',
    ], runInShell: true);
  } catch (_) {}
}

/// Retrieve motherboard UUID on Windows, fallback to MAC address.
String getHwid() {
  if (!Platform.isWindows) return 'UNKNOWN_HWID';
  try {
    final res = Process.runSync('wmic', ['csproduct', 'get', 'uuid']);
    if (res.exitCode == 0) {
      final lines = res.stdout.toString().split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isNotEmpty && !line.toLowerCase().startsWith('uuid')) {
          if (line.length > 10) return line;
        }
      }
    }
  } catch (_) {}

  // Fallback MAC-like node
  try {
    final res = Process.runSync('getmac', []);
    if (res.exitCode == 0) {
      final lines = res.stdout.toString().split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isNotEmpty && !line.toLowerCase().startsWith('physical')) {
          final match = RegExp(
            r'([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}',
          ).firstMatch(line);
          if (match != null) {
            return 'MAC-${match.group(0)!.replaceAll('-', '').replaceAll(':', '').toUpperCase()}';
          }
        }
      }
    }
  } catch (_) {}

  // Last resort fallback
  return 'HWID-${Platform.localHostname.toUpperCase()}';
}

/// Resolves path parameters for the local cached license key.
/// Returns a tuple of (localFolder, localKeyPath, syncTimestampPath).
(String, String, String) getKeyPaths(String appId) {
  final appData = Platform.environment['APPDATA'] ?? Directory.current.path;
  final localFolder = p.join(appData, 'JA_PROJECT', 'JA_key');
  final keyPath = p.join(localFolder, '${appId.toUpperCase()}.key');
  final syncPath = p.join(localFolder, '${appId.toUpperCase()}_last_sync.txt');
  return (localFolder, keyPath, syncPath);
}

/// Bitwise XOR decrypts character-by-character.
String _xorDecrypt(String hexStr, String secret) {
  final buffer = StringBuffer();
  for (int i = 0; i < hexStr.length ~/ 2; i++) {
    final byteVal = int.parse(hexStr.substring(2 * i, 2 * i + 2), radix: 16);
    final passChar = secret.codeUnitAt(i % secret.length);
    buffer.writeCharCode(byteVal ^ passChar);
  }
  return buffer.toString();
}

/// HMAC-SHA256 signature calculator.
String _sign(String payload, String secret) {
  final secretBytes = utf8.encode(secret);
  final payloadBytes = utf8.encode(payload);
  final hmac = Hmac(sha256, secretBytes);
  return hmac.convert(payloadBytes).toString();
}

/// Decode and decrypt license key details.
Map<String, dynamic> _decryptKey(
  String encoded,
  String secret,
  String expectedAppId,
) {
  final result = <String, dynamic>{
    'valid': false,
    'expired': true,
    'expiry_date': null,
    'app_id': null,
    'hwid': '',
    'error': null,
  };

  try {
    // 1. Decode Base64
    final rawBytes = base64.decode(encoded);
    final raw = utf8.decode(rawBytes);

    if (!raw.contains(_sep)) {
      result['error'] = 'Định dạng key không hợp lệ (thiếu separator).';
      return result;
    }

    final sepIdx = raw.lastIndexOf(_sep);
    final payload = raw.substring(0, sepIdx);
    final signature = raw.substring(sepIdx + 1);

    // 2. Verify HMAC Signature
    final expectedSig = _sign(payload, secret);
    if (expectedSig != signature) {
      result['error'] = 'Chữ ký HMAC không khớp — key có thể đã bị giả mạo!';
      return result;
    }

    // 3. XOR Decrypt Payload
    final inner = _xorDecrypt(payload, secret);
    if (!inner.contains(_innerSep)) {
      result['error'] = 'Key không chứa App ID — key cũ không còn hợp lệ.';
      return result;
    }

    final parts = inner.split(_innerSep);
    final expiryDate = parts[0];
    final appIdInKey = parts[1];
    final hwidInKey = parts.length > 2 ? parts.sublist(2).join(_innerSep) : '';

    if (expiryDate.length != 8 || int.tryParse(expiryDate) == null) {
      result['error'] = 'Nội dung key giải mã không hợp lệ: \'$expiryDate\'';
      return result;
    }

    if (appIdInKey != expectedAppId) {
      result['error'] =
          'Key này dành cho phần mềm \'$appIdInKey\', không dùng được cho \'$expectedAppId\'.';
      result['app_id'] = appIdInKey;
      return result;
    }

    if (hwidInKey.isNotEmpty) {
      final currentHwid = getHwid();
      if (hwidInKey.toUpperCase() != currentHwid.toUpperCase()) {
        result['error'] =
            'Key được đăng ký cho máy \'$hwidInKey\', không trùng với mã máy hiện tại \'$currentHwid\'.';
        return result;
      }
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    result['valid'] = true;
    result['expiry_date'] = expiryDate;
    result['app_id'] = appIdInKey;
    result['hwid'] = hwidInKey;
    result['expired'] = expiryDate.compareTo(todayStr) < 0;
  } catch (e) {
    result['error'] = 'Lỗi giải mã: $e';
  }

  return result;
}

/// Retrieve current cached key validation details.
LicenseInfo getLicenseInfo(String appId) {
  final (localFolder, localPath, _) = getKeyPaths(appId);
  final hwid = getHwid();

  if (!File(localPath).existsSync()) {
    return LicenseInfo(
      status: 'Chưa kích hoạt',
      appId: appId,
      daysRemaining: 0,
      valid: false,
      expired: true,
      error: 'Chưa có file bản quyền.',
      hwid: hwid,
    );
  }

  try {
    final encoded = File(localPath).readAsStringSync().trim();
    final res = _decryptKey(encoded, _defaultSecret, appId);

    if (res['valid'] == true) {
      final expiryDateStr = res['expiry_date'] as String;
      final expired = res['expired'] as bool;
      int days = 0;
      try {
        final expYr = int.parse(expiryDateStr.substring(0, 4));
        final expMo = int.parse(expiryDateStr.substring(4, 6));
        final expDy = int.parse(expiryDateStr.substring(6, 8));
        final expDate = DateTime(expYr, expMo, expDy);
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        days = expDate.difference(todayMidnight).inDays;
      } catch (_) {}

      return LicenseInfo(
        status: expired ? 'Đã hết hạn' : 'Đang hoạt động',
        appId: appId,
        expiryDate: expiryDateStr,
        daysRemaining: days,
        valid: true,
        expired: expired,
        error: res['error'] as String?,
        hwid: hwid,
      );
    } else {
      return LicenseInfo(
        status: 'Key không hợp lệ',
        appId: appId,
        daysRemaining: 0,
        valid: false,
        expired: true,
        error: (res['error'] as String?) ?? 'Lỗi không rõ.',
        hwid: hwid,
      );
    }
  } catch (e) {
    return LicenseInfo(
      status: 'Lỗi đọc file',
      appId: appId,
      daysRemaining: 0,
      valid: false,
      expired: true,
      error: 'Không thể đọc file key: $e',
      hwid: hwid,
    );
  }
}

/// Run silent check and auto-sync from server once a day.
Future<(bool, String)> checkLicenseSilent(String appId) async {
  final serverPath = _defaultServerPath.replaceAll(
    '{APP_ID}',
    appId.toUpperCase(),
  );
  final (localFolder, localPath, syncPath) = getKeyPaths(appId);
  final today = DateTime.now();
  final todayStr =
      '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

  // Ensure directories exist
  Directory(localFolder).createSync(recursive: true);

  // Sync once a day
  String lastSync = '';
  if (File(syncPath).existsSync()) {
    try {
      lastSync = File(syncPath).readAsStringSync().trim();
    } catch (_) {}
  }

  if (lastSync != todayStr) {
    try {
      final mounted = await mountShare();
      if (mounted) {
        final sFile = File(serverPath);
        if (sFile.existsSync()) {
          sFile.copySync(localPath);
          File(syncPath).writeAsStringSync(todayStr);
        }
      }
    } catch (_) {}
  }

  if (!File(localPath).existsSync()) {
    return (false, 'NO_KEY_FILE:Chưa có file bản quyền.');
  }

  String encoded = '';
  try {
    encoded = File(localPath).readAsStringSync().trim();
  } catch (e) {
    return (false, 'READ_ERROR:$e');
  }

  if (encoded.isEmpty) {
    return (false, 'READ_ERROR:File bản quyền trống.');
  }

  final result = _decryptKey(encoded, _defaultSecret, appId);
  if (result['valid'] != true) {
    return (false, 'INVALID:${result['error'] ?? "Key không hợp lệ."}');
  }

  if (result['expired'] == true) {
    final exp = result['expiry_date'] as String;
    final expFmt =
        '${exp.substring(0, 4)}-${exp.substring(4, 6)}-${exp.substring(6)}';

    // Attempt auto-refresh from server
    try {
      final mounted = await mountShare();
      if (mounted && File(serverPath).existsSync()) {
        File(serverPath).copySync(localPath);
        try {
          File(syncPath).deleteSync();
        } catch (_) {}
        final encoded2 = File(localPath).readAsStringSync().trim();
        final r2 = _decryptKey(encoded2, _defaultSecret, appId);
        if (r2['valid'] == true && r2['expired'] != true) {
          final exp2 = r2['expiry_date'] as String;
          final exp2Fmt =
              '${exp2.substring(0, 4)}-${exp2.substring(4, 6)}-${exp2.substring(6)}';
          return (true, 'Bản quyền hợp lệ (hết hạn: $exp2Fmt)');
        }
      }
    } catch (_) {}
    return (
      false,
      'EXPIRED:Bản quyền đã hết hạn ($expFmt). Liên hệ Admin để gia hạn.',
    );
  }

  final exp = result['expiry_date'] as String;
  final expFmt =
      '${exp.substring(0, 4)}-${exp.substring(4, 6)}-${exp.substring(6)}';
  return (true, 'Bản quyền hợp lệ (hết hạn: $expFmt)');
}

/// Trigger sync from server explicitly.
Future<(bool, String)> forceSyncServer(String appId) async {
  final serverPath = _defaultServerPath.replaceAll(
    '{APP_ID}',
    appId.toUpperCase(),
  );
  final (localFolder, localPath, syncPath) = getKeyPaths(appId);
  final today = DateTime.now();
  final todayStr =
      '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

  try {
    final mounted = await mountShare();
    if (!mounted) {
      return (false, 'Không thể kết nối LAN share.');
    }

    final sFile = File(serverPath);
    if (!sFile.existsSync()) {
      return (false, 'Không tìm thấy key trên server: $serverPath');
    }

    sFile.copySync(localPath);
    File(syncPath).writeAsStringSync(todayStr);

    final encoded = sFile.readAsStringSync().trim();
    final r = _decryptKey(encoded, _defaultSecret, appId);
    if (r['valid'] == true) {
      final exp = r['expiry_date'] as String;
      final expFmt =
          '${exp.substring(0, 4)}-${exp.substring(4, 6)}-${exp.substring(6)}';
      return (true, 'Đồng bộ thành công! Hết hạn: $expFmt');
    }
    return (false, 'Key trên server không hợp lệ: ${r['error']}');
  } catch (e) {
    return (false, 'Lỗi đồng bộ: $e');
  } finally {
    await unmountShare();
  }
}

/// Save a manually pasted license key.
(bool, String) saveKey(String encodedKey, String appId) {
  encodedKey = encodedKey.trim();
  final result = _decryptKey(encodedKey, _defaultSecret, appId);

  if (result['valid'] != true) {
    return (false, (result['error'] as String?) ?? 'Key không hợp lệ.');
  }

  if (result['expired'] == true) {
    final exp = result['expiry_date'] as String;
    final expFmt =
        '${exp.substring(0, 4)}-${exp.substring(4, 6)}-${exp.substring(6)}';
    return (false, 'Key hợp lệ nhưng đã hết hạn ($expFmt).');
  }

  final (localFolder, localPath, syncPath) = getKeyPaths(appId);
  try {
    Directory(localFolder).createSync(recursive: true);
    File(localPath).writeAsStringSync(encodedKey);
    try {
      File(syncPath).deleteSync();
    } catch (_) {}
    final exp = result['expiry_date'] as String;
    final expFmt =
        '${exp.substring(0, 4)}-${exp.substring(4, 6)}-${exp.substring(6)}';
    return (true, 'Kích hoạt thành công! Hết hạn: $expFmt');
  } catch (e) {
    return (false, 'Không thể lưu key: $e');
  }
}
