// lib/modules/constants.dart
import 'dart:io';
import 'package:path/path.dart' as p;

const String appId = 'JA_IQ5_REFLASH';
const String appName = 'JA IQ5 Reflash';
const String appVersion = '1.3.1+4';
const String appUserModelId = 'JATech.JA_IQ5_REFLASH.1.0';

// Qualcomm EDL USB Identifiers
const int edlVid = 0x05C6;
const int edlPid = 0x9008;

// Flash parameters
const int maxDevices = 8;
const int devicePollMs = 2000;

// XML & Elf details
const String rawprogramXml = 'rawprogram_unsparse0.xml';
const String patchXml = 'patch0.xml';
const String firehoseElf = 'prog_firehose_ddr.elf';

// Default Paths
final String baseDir = File(Platform.resolvedExecutable).parent.path;
final String defaultFwDir = p.join(baseDir, 'assets', 'data', 'firmware');

// Standard binary paths (can be configured or dynamically searched)
const String defaultPlatformToolsDir = r'C:\Program Files (x86)\platform-tools';
const String defaultQpstBinDir = r'C:\Program Files (x86)\Qualcomm\QPST\bin';

final String adbExePath = _resolveBinary(defaultPlatformToolsDir, 'adb.exe');
final String fastbootExePath = _resolveBinary(
  defaultPlatformToolsDir,
  'fastboot.exe',
);
final String fhLoaderExePath = _resolveBinary(
  defaultQpstBinDir,
  'fh_loader.exe',
);

String _resolveBinary(String defaultDir, String fileName) {
  // 1. Try local bin/ folder first
  final localBinPath = p.join(baseDir, 'bin', fileName);
  if (File(localBinPath).existsSync()) {
    return localBinPath;
  }
  // 2. Try default directory second
  final defaultPath = p.join(defaultDir, fileName);
  if (File(defaultPath).existsSync()) {
    return defaultPath;
  }
  // 3. Try current directory or PATH fallback
  final localPath = p.join(baseDir, fileName);
  if (File(localPath).existsSync()) {
    return localPath;
  }
  // 4. Fallback to filename so OS PATH search resolves it
  return fileName;
}

/// Set to true when app is launched with -debug, --debug, or -d flag
bool isCliDebug = false;

/// Get AOT compilation or binary build time
String getBuildTime() {
  try {
    final exe = File(Platform.resolvedExecutable);
    final appSo = File(p.join(exe.parent.path, 'data', 'app.so'));
    final target = appSo.existsSync() ? appSo : exe;
    if (target.existsSync()) {
      final dt = target.lastModifiedSync();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
  } catch (_) {}
  return '';
}
