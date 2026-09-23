import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';
import '../constants.dart';

/// Returns actionable errors without touching the device.
List<String> validateFirmware(String directory) {
  final errors = <String>[];
  try {
    final root = Directory(directory).resolveSymbolicLinksSync();
    for (final name in [firehoseElf, rawprogramXml, patchXml]) {
      final file = File(p.join(root, name));
      if (!file.existsSync() || file.lengthSync() == 0) {
        errors.add('Missing or empty: $name');
      } else if (!p.isWithin(root, file.resolveSymbolicLinksSync())) {
        errors.add('File outside firmware directory: $name');
      }
    }
    if (errors.isNotEmpty) return errors;
    var imageCount = 0;
    for (final name in [rawprogramXml, patchXml]) {
      final document = XmlDocument.parse(
        File(p.join(root, name)).readAsStringSync(),
      );
      final expected = name == rawprogramXml ? 'data' : 'patches';
      if (document.rootElement.name.local != expected) {
        errors.add('Invalid XML root in $name (expected $expected)');
      }
      for (final node in document.descendants.whereType<XmlElement>()) {
        final fileName = node.getAttribute('filename')?.trim();
        // Empty program filenames mean intentionally skipped partitions;
        // DISK is the patch protocol target, not an image file.
        if (fileName == null ||
            fileName.isEmpty ||
            (name == patchXml && fileName == 'DISK')) {
          continue;
        }
        if (name == rawprogramXml && node.name.local == 'program') {
          imageCount++;
        }
        final relative = fileName.replaceAll('\\', '/');
        if (p.posix.isAbsolute(relative) ||
            p.windows.isAbsolute(fileName) ||
            relative.split('/').contains('..') ||
            relative.contains(':')) {
          errors.add('Unsafe image path: $fileName');
          continue;
        }
        final file = File(p.join(root, relative));
        if (!file.existsSync() || file.lengthSync() == 0) {
          errors.add('Missing or empty image: $fileName');
        } else if (!p.isWithin(root, file.resolveSymbolicLinksSync())) {
          errors.add('Image outside firmware directory: $fileName');
        }
      }
    }
    if (imageCount == 0) errors.add('No program images in $rawprogramXml');
  } catch (error) {
    errors.add('Cannot read firmware: $error');
  }
  return errors;
}
