// lib/modules/utils.dart
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:win32/win32.dart';


final _shell32 = DynamicLibrary.open('shell32.dll');
final _isUserAnAdmin = _shell32
    .lookupFunction<Int32 Function(), int Function()>('IsUserAnAdmin');

/// Check if the process has administrative privileges on Windows.
bool isAdmin() {
  if (!Platform.isWindows) return false;
  try {
    return _isUserAnAdmin() != 0;
  } catch (_) {
    return false;
  }
}

/// Request Administrator elevation using native Win32 ShellExecute (runas verb).
/// Returns true if the elevated process was successfully spawned.
bool elevateProcess() {
  if (!Platform.isWindows) return false;
  final exePath = Platform.resolvedExecutable;
  final exeDir = File(exePath).parent.path;

  final lpOperation = 'runas'.toNativeUtf16();
  final lpFile = exePath.toNativeUtf16();
  final lpDirectory = exeDir.toNativeUtf16();

  try {
    final result = ShellExecute(
      0,
      lpOperation,
      lpFile,
      nullptr,
      lpDirectory,
      SW_SHOWNORMAL,
    );
    return result > 32;
  } catch (_) {
    return false;
  } finally {
    free(lpOperation);
    free(lpFile);
    free(lpDirectory);
  }
}

/// Compute SHA-256 hex digest of a file asynchronously.
Future<String> fileSha256(String path) async {
  final file = File(path);
  if (!await file.exists()) return '';
  try {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  } catch (_) {
    return '';
  }
}

/// Compute SHA-256 hex digest of a file synchronously.
String fileSha256Sync(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  try {
    final bytes = file.readAsBytesSync();
    return sha256.convert(bytes).toString();
  } catch (_) {
    return '';
  }
}

/// Format bytes into human readable format.
String formatBytes(int bytes) {
  if (bytes < 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unitIdx = 0;
  while (value >= 1024 && unitIdx < units.length - 1) {
    value /= 1024;
    unitIdx++;
  }
  return '${value.toStringAsFixed(1)} ${units[unitIdx]}';
}

/// Stop the Qualcomm MTU Service (qcmtusvc).
Future<bool> stopQualcommService() async {
  if (!Platform.isWindows) return true;
  try {
    // Primary: Try using PowerShell which handles states and errors better
    final psResult = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-Command',
        'Stop-Service -Name qcmtusvc -Force -ErrorAction SilentlyContinue; '
        'Get-Service -Name qcmtusvc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status'
      ],
    );
    final psOutput = psResult.stdout.toString().trim();
    if (psOutput.isEmpty || psOutput == 'Stopped') {
      return true; // Service doesn't exist or is stopped
    }

    // Fallback 1: sc stop
    final result = await Process.run('sc', ['stop', 'qcmtusvc']);
    final output = '${result.stdout}${result.stderr}';
    if (result.exitCode == 0 ||
        output.contains('1062') ||
        output.contains('1060') ||
        output.contains('has not been started') ||
        output.contains('does not exist')) {
      return true;
    }

    // Fallback 2: net stop
    final r2 = await Process.run('net', ['stop', 'qcmtusvc'], runInShell: true);
    final o2 = '${r2.stdout}${r2.stderr}';
    if (r2.exitCode == 0 ||
        o2.toLowerCase().contains('not started') ||
        o2.toLowerCase().contains('not exist')) {
      return true;
    }
  } catch (_) {}
  return false;
}

/// Start the Qualcomm MTU Service (qcmtusvc).
Future<bool> startQualcommService() async {
  if (!Platform.isWindows) return true;
  try {
    final result = await Process.run('sc', ['start', 'qcmtusvc']);
    return result.exitCode == 0;
  } catch (_) {}
  return false;
}

/// Helper to clamp value between lower and upper bound.
double clamp(double value, double lower, double upper) {
  if (value < lower) return lower;
  if (value > upper) return upper;
  return value;
}


/// Opens modern Windows Explorer Folder Dialog with address bar, search, and quick access.
Future<String?> selectDirectory({
  String? initialDirectory,
  String? dialogTitle,
}) async {
  try {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'Select Firmware Directory',
      initialDirectory: (initialDirectory != null &&
              initialDirectory.isNotEmpty &&
              Directory(initialDirectory).existsSync())
          ? initialDirectory
          : null,
    );
    if (selected != null && selected.trim().isNotEmpty) {
      return selected.trim();
    }
  } catch (_) {}
  return null;
}

/// A lightweight INI config parser and writer.
class IniConfig {
  final Map<String, Map<String, String>> _data = {};

  /// Load INI content from string.
  void load(String content) {
    String currentSection = '';
    final lines = const LineSplitter().convert(content);
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) {
        continue;
      }
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1).trim();
        _data[currentSection] ??= {};
      } else if (line.contains('=')) {
        final idx = line.indexOf('=');
        final key = line.substring(0, idx).trim();
        final value = line.substring(idx + 1).trim();
        if (currentSection.isNotEmpty) {
          _data[currentSection]![key] = value;
        }
      }
    }
  }

  /// Get value from section & key, fallback if not found.
  String get(String section, String key, String defaultValue) {
    return _data[section]?[key] ?? defaultValue;
  }

  /// Set value in section & key.
  void set(String section, String key, String value) {
    _data[section] ??= {};
    _data[section]![key] = value;
  }

  /// Serialize database structure back to INI string.
  String save() {
    final buffer = StringBuffer();
    _data.forEach((section, keys) {
      buffer.writeln('[$section]');
      keys.forEach((key, value) {
        buffer.writeln('$key = $value');
      });
      buffer.writeln();
    });
    return buffer.toString();
  }
}
