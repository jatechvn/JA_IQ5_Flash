// lib/modules/logic/sahara.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

import '../i18n.dart';
import '../utils.dart';
import 'win_serial.dart';

const int saharaHello = 0x01;
const int saharaHelloRsp = 0x02;
const int saharaReadData = 0x03;
const int saharaEndImageTx = 0x04;
const int saharaDone = 0x05;
const int saharaDoneRsp = 0x06;
const int saharaReset = 0x07;
const int saharaResetRsp = 0x08;
const int saharaReadData64 = 0x12;

const double _helloWaitS = 8.0; // Wait up to 8s for HELLO after service stop
const double _xferTimeoutS = 10.0;
const int _chunkReportBytes = 256 * 1024; // 256 KB

/// Unpacks a 64-bit unsigned integer from ByteData since getUint64 is not natively standard.
int _getUint64(ByteData data, int byteOffset, Endian endian) {
  if (endian == Endian.little) {
    final low = data.getUint32(byteOffset, Endian.little);
    final high = data.getUint32(byteOffset + 4, Endian.little);
    return (high << 32) | low;
  } else {
    final high = data.getUint32(byteOffset, Endian.big);
    final low = data.getUint32(byteOffset + 4, Endian.big);
    return (high << 32) | low;
  }
}

/// Helper to read exactly [count] bytes with timeout.
Future<Uint8List> _readBytesExactly(WinSerial serial, int count) async {
  final builder = BytesBuilder();
  int remaining = count;
  final stopwatch = Stopwatch()..start();
  while (remaining > 0 && stopwatch.elapsedMilliseconds < 2000) {
    final chunk = serial.read(remaining);
    if (chunk.isNotEmpty) {
      builder.add(chunk);
      remaining -= chunk.length;
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
  return builder.takeBytes();
}

/// Read one complete Sahara packet: [cmd:4][len:4][payload:(len-8)]
Future<Uint8List?> _readPacket(WinSerial serial) async {
  final hdr = await _readBytesExactly(serial, 8);
  if (hdr.length < 8) return null;

  final view = ByteData.sublistView(hdr);
  final len = view.getUint32(4, Endian.little);

  if (len > 8) {
    final payload = await _readBytesExactly(serial, len - 8);
    if (payload.length < len - 8) {
      return null; // Incomplete payload / timeout
    }
    final full = Uint8List(len);
    full.setRange(0, 8, hdr);
    full.setRange(8, len, payload);
    return full;
  }
  return hdr;
}

/// Formulates a SAHARA_HELLO_RSP packet.
Uint8List _helloResp(int version, int versionSup, int mode) {
  final data = ByteData(48);
  data.setUint32(0, saharaHelloRsp, Endian.little);
  data.setUint32(4, 48, Endian.little);
  data.setUint32(8, version, Endian.little);
  data.setUint32(12, versionSup, Endian.little);
  data.setUint32(16, 0, Endian.little); // Status success
  data.setUint32(20, mode, Endian.little);
  // Padding with 0s
  for (int i = 24; i < 48; i += 4) {
    data.setUint32(i, 0, Endian.little);
  }
  return data.buffer.asUint8List();
}

/// Parse Sahara status from SAHARA_END_IMAGE_TX packet.
int _parseEndImageStatus(Uint8List pkt) {
  if (pkt.length >= 16) {
    final view = ByteData.sublistView(pkt);
    return view.getUint32(12, Endian.little);
  }
  if (pkt.length >= 12) {
    final view = ByteData.sublistView(pkt);
    return view.getUint32(8, Endian.little);
  }
  return 0xFFFFFFFF;
}

/// Uploads firehose programmer ELF to device in Sahara mode.
/// Returns (success, message).
Future<(bool, String)> saharaUploadProgrammer({
  required String port,
  required String elfPath,
  void Function(String msg, String level)? onLog,
  void Function(int percentage)? onProgress,
  bool helloCaptured = false,
  int helloVersion = 2,
  int helloVersionSup = 1,
  int helloMode = 0,
}) async {
  void log(String msg, [String level = 'info']) {
    if (onLog != null) {
      onLog(msg, level);
    }
  }

  final file = File(elfPath);
  if (!file.existsSync()) {
    return (false, 'Programmer not found: $elfPath');
  }

  final elfData = file.readAsBytesSync();
  final elfSize = elfData.length;
  log(
    'Programmer: ${p.basename(elfPath)} (${(elfSize / 1024 / 1024).toStringAsFixed(1)} MB)',
  );

  // Verify ELF Magic: 0x7F 'E' 'L' 'F'
  if (elfData.length < 4 ||
      elfData[0] != 0x7F ||
      elfData[1] != 0x45 ||
      elfData[2] != 0x4C ||
      elfData[3] != 0x46) {
    return (false, 'Invalid ELF magic.');
  }

  final serial = WinSerial(port);
  if (!serial.open(baudrate: 115200, timeoutSeconds: 1.0)) {
    return (false, 'Could not open serial port $port');
  }

  try {
    int version = 2;
    int versionSup = 1;
    int mode = 0;

    // ══════════════════════════════════════════════════════════════════
    //  Strategy A — Pre-captured HELLO from DeviceManager
    // ══════════════════════════════════════════════════════════════════
    if (helloCaptured) {
      version = helloVersion;
      versionSup = helloVersionSup;
      mode = helloMode;
      log('[Strategy A] Pre-captured HELLO v=$version mode=$mode');
      serial.write(_helloResp(version, versionSup, mode));
      serial.flush();
      serial.setTimeout(_xferTimeoutS);
      return await _transferLoop(
        serial,
        elfData,
        elfSize,
        null,
        log,
        onProgress,
      );
    }

    // ══════════════════════════════════════════════════════════════════
    //  Strategy B — Poll for HELLO / READ_DATA / END_IMAGE_TX
    // ══════════════════════════════════════════════════════════════════
    log(
      '[Strategy B] Waiting for HELLO / READ_DATA (${_helloWaitS.toStringAsFixed(0)}s)…',
    );
    final stopwatch = Stopwatch()..start();
    final waitTimeoutMs = (_helloWaitS * 1000).toInt();
    bool gotHello = false;

    while (stopwatch.elapsedMilliseconds < waitTimeoutMs) {
      final pkt = await _readPacket(serial);
      if (pkt == null) {
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }

      final view = ByteData.sublistView(pkt);
      final cmd = view.getUint32(0, Endian.little);

      if (cmd == saharaHello && pkt.length >= 24) {
        version = view.getUint32(8, Endian.little);
        versionSup = view.getUint32(12, Endian.little);
        mode = view.getUint32(20, Endian.little);
        gotHello = true;
        log('[Strategy B] HELLO v=$version mode=$mode');
        break;
      } else if (cmd == saharaReadData || cmd == saharaReadData64) {
        log('[Strategy B] DEVICE ALREADY IN IMAGE_TX STATE');
        serial.setTimeout(_xferTimeoutS);
        return await _transferLoop(
          serial,
          elfData,
          elfSize,
          pkt,
          log,
          onProgress,
        );
      } else if (cmd == saharaEndImageTx) {
        final status = _parseEndImageStatus(pkt);
        log(
          '[Strategy B] END_IMAGE_TX status=0x${status.toRadixString(16).toUpperCase()}',
        );
        if (status == 0) {
          log(
            '[Strategy B] status=0 → Sending DONE (completed by system service)',
          );
          final donePkt = ByteData(8);
          donePkt.setUint32(0, saharaDone, Endian.little);
          donePkt.setUint32(4, 8, Endian.little);
          serial.write(donePkt.buffer.asUint8List());
          serial.flush();

          serial.close();
          if (onProgress != null) onProgress(100);
          return (true, 'Programmer uploaded (session completed via DONE)');
        } else {
          log('[Strategy B] status error — waiting for HELLO retry…', 'warn');
          // Extend timeout for retry
          final extendedWatch = Stopwatch()..start();
          while (extendedWatch.elapsedMilliseconds < 15000) {
            final retryPkt = await _readPacket(serial);
            if (retryPkt != null) {
              final rView = ByteData.sublistView(retryPkt);
              if (rView.getUint32(0, Endian.little) == saharaHello) {
                version = rView.getUint32(8, Endian.little);
                versionSup = rView.getUint32(12, Endian.little);
                mode = rView.getUint32(20, Endian.little);
                gotHello = true;
                log('[Strategy B] HELLO retry captured');
                break;
              }
            }
            await Future.delayed(const Duration(milliseconds: 10));
          }
          break;
        }
      }
    }

    if (gotHello) {
      serial.write(_helloResp(version, versionSup, mode));
      serial.flush();
      serial.setTimeout(_xferTimeoutS);
      return await _transferLoop(
        serial,
        elfData,
        elfSize,
        null,
        log,
        onProgress,
      );
    }

    // ══════════════════════════════════════════════════════════════════
    //  Strategy C — Blind HELLO_RESP
    // ══════════════════════════════════════════════════════════════════
    log('[Strategy C] Sending blind HELLO_RESP…', 'warn');
    serial.write(_helloResp(2, 1, 0));
    serial.flush();
    await Future.delayed(const Duration(milliseconds: 30));

    serial.setTimeout(5.0);

    final strategyCStopwatch = Stopwatch()..start();
    while (strategyCStopwatch.elapsedMilliseconds < 30000) {
      final pkt = await _readPacket(serial);
      if (pkt == null) {
        await Future.delayed(const Duration(milliseconds: 10));
        continue;
      }

      final view = ByteData.sublistView(pkt);
      final cmd = view.getUint32(0, Endian.little);

      if (cmd == saharaReadData || cmd == saharaReadData64) {
        log('[Strategy C] READ_DATA received — starting transfer');
        serial.setTimeout(_xferTimeoutS);
        return await _transferLoop(
          serial,
          elfData,
          elfSize,
          pkt,
          log,
          onProgress,
        );
      } else if (cmd == saharaHello) {
        version = pkt.length >= 12 ? view.getUint32(8, Endian.little) : 2;
        versionSup = pkt.length >= 16 ? view.getUint32(12, Endian.little) : 1;
        mode = pkt.length >= 24 ? view.getUint32(20, Endian.little) : 0;
        log('[Strategy C] HELLO retry — responding');
        serial.write(_helloResp(version, versionSup, mode));
        serial.flush();
      } else if (cmd == saharaEndImageTx) {
        final status = _parseEndImageStatus(pkt);
        log(
          '[Strategy C] END_IMAGE_TX status=0x${status.toRadixString(16).toUpperCase()}',
        );
        if (status == 0) {
          log('[Strategy C] status=0 → Sending DONE ✔');
          final donePkt = ByteData(8);
          donePkt.setUint32(0, saharaDone, Endian.little);
          donePkt.setUint32(4, 8, Endian.little);
          serial.write(donePkt.buffer.asUint8List());
          serial.flush();

          serial.close();
          if (onProgress != null) onProgress(100);
          return (true, 'Programmer uploaded (completed via DONE)');
        } else {
          log(
            '[Strategy C] END_IMAGE_TX error — sending RESET to re-enumerate…',
            'warn',
          );
          final resetPkt = ByteData(8);
          resetPkt.setUint32(0, saharaReset, Endian.little);
          resetPkt.setUint32(4, 8, Endian.little);
          serial.write(resetPkt.buffer.asUint8List());
          serial.flush();
          serial.close();
          return (
            false,
            tr('log_sahara_reset_sent').replaceAll('{port}', port),
          );
        }
      }
    }

    serial.close();
    return (false, tr('log_sahara_all_failed').replaceAll('{port}', port));
  } catch (e) {
    serial.close();
    return (false, 'Sahara upload error: $e');
  }
}

/// Core transfer loop responding to READ_DATA requests.
Future<(bool, String)> _transferLoop(
  WinSerial serial,
  Uint8List elfData,
  int elfSize,
  Uint8List? firstPacket,
  void Function(String msg, [String lvl]) log,
  void Function(int pct)? onProgress,
) async {
  int bytesSent = 0;
  int lastPct = -1;
  int lastReportBytes = 0;
  Uint8List? pending = firstPacket;

  while (true) {
    Uint8List? pkt;
    if (pending != null) {
      pkt = pending;
      pending = null;
    } else {
      pkt = await _readPacket(serial);
    }

    if (pkt == null) {
      if (bytesSent == 0) {
        return (false, 'No READ_DATA after HELLO_RESP.');
      }
      return (false, 'Transfer timeout after $bytesSent bytes.');
    }

    // Diagnostic hex log for every received packet in the loop
    final pktHex = pkt.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
    log('  [Sahara] DEBUG: Received packet hex (len=${pkt.length}): $pktHex', 'debug');

    final view = ByteData.sublistView(pkt);
    final cmd = view.getUint32(0, Endian.little);

    if (cmd == saharaReadData || cmd == saharaReadData64) {
      int imageId = 0;
      int dataOffset = 0;
      int dataLength = 0;

      if (cmd == saharaReadData64) {
        if (pkt.length < 32) {
          return (
            false,
            'READ_DATA_64 package size too small (${pkt.length} bytes).',
          );
        }
        imageId = _getUint64(view, 8, Endian.little);
        dataOffset = _getUint64(view, 16, Endian.little);
        dataLength = _getUint64(view, 24, Endian.little);
      } else {
        if (pkt.length < 20) {
          return (
            false,
            'READ_DATA package size too small (${pkt.length} bytes).',
          );
        }
        imageId = view.getUint32(8, Endian.little);
        dataOffset = view.getUint32(12, Endian.little);
        dataLength = view.getUint32(16, Endian.little);
      }

      final endOffset = dataOffset + dataLength;
      log(
        '  READ${cmd == saharaReadData64 ? "_64" : ""} id=$imageId offset=$dataOffset len=$dataLength',
        'debug',
      );

      if (endOffset > elfSize) {
        return (
          false,
          'READ_DATA index out of range: $dataOffset + $dataLength > $elfSize',
        );
      }

      final chunk = elfData.sublist(dataOffset, dataOffset + dataLength);
      final written = serial.write(chunk);
      serial.flush();
      if (written != chunk.length) {
        log('  [Sahara] WARNING: Serial write mismatch: wrote $written of ${chunk.length} bytes!', 'warn');
      }
      if (dataOffset == 0) {
        final hexStr = chunk.take(16).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
        log('  [Sahara] DEBUG: First chunk header hex: $hexStr', 'debug');
      }
      bytesSent += dataLength;

      if (bytesSent - lastReportBytes >= _chunkReportBytes) {
        lastReportBytes = bytesSent;
        final pct = (bytesSent / elfSize * 100).clamp(0, 99).toInt();
        if (pct != lastPct) {
          lastPct = pct;
          log(
            '  Uploading… $pct% (${bytesSent ~/ 1024}/${elfSize ~/ 1024} KB)',
          );
          if (onProgress != null) {
            onProgress(pct);
          }
        }
      }
    } else if (cmd == saharaEndImageTx) {
      final status = _parseEndImageStatus(pkt);
      log(
        '  END_IMAGE_TX status=0x${status.toRadixString(16).toUpperCase()} bytes_sent=$bytesSent',
      );
      if (status != 0) {
        return (
          false,
          'END_IMAGE_TX error status=0x${status.toRadixString(16).toUpperCase()} — programmer rejected.\n'
              '  Ensure programmer is correct for this device.',
        );
      }

      log('Programmer uploaded ($bytesSent bytes)');
      final donePkt = ByteData(8);
      donePkt.setUint32(0, saharaDone, Endian.little);
      donePkt.setUint32(4, 8, Endian.little);
      serial.write(donePkt.buffer.asUint8List());
      serial.flush();

      // read final done_rsp
      serial.read(8);

      serial.close();
      if (onProgress != null) onProgress(100);
      return (true, 'Programmer uploaded successfully ($bytesSent bytes).');
    } else if (cmd == saharaHello) {
      final v = pkt.length >= 12 ? view.getUint32(8, Endian.little) : 2;
      final vs = pkt.length >= 16 ? view.getUint32(12, Endian.little) : 1;
      final m = pkt.length >= 24 ? view.getUint32(20, Endian.little) : 0;
      log('  HELLO retry v=$v mode=$m — resending HELLO_RESP', 'warn');
      serial.write(_helloResp(v, vs, m));
      serial.flush();
    } else {
      log('  Unexpected cmd=0x${cmd.toRadixString(16).toUpperCase()}', 'warn');
    }
  }
}

/// Reset device via Sahara reset command.
Future<(bool, String)> saharaResetPort(String port) async {
  try {
    // Stop qcmtusvc so the device can boot properly and doesn't get captured again
    await stopQualcommService();

    final serial = WinSerial(port);
    if (!serial.open(baudrate: 115200, timeoutSeconds: 0.3)) {
      return (false, 'Could not open serial port $port');
    }

    try {
      // Blind HELLO_RESP to clear any stale state
      serial.write(_helloResp(2, 1, 0));
      serial.flush();
      await Future.delayed(const Duration(milliseconds: 50));

      // Send RESET
      final resetPkt = ByteData(8);
      resetPkt.setUint32(0, saharaReset, Endian.little);
      resetPkt.setUint32(4, 8, Endian.little);
      serial.write(resetPkt.buffer.asUint8List());
      serial.flush();

      // Quick read for RESET_RESP (device might reboot immediately)
      final resp = serial.read(8);
      if (resp.length >= 4) {
        final view = ByteData.sublistView(resp);
        final cmd = view.getUint32(0, Endian.little);
        if (cmd == saharaResetRsp) {
          serial.close();
          return (true, 'RESET_RESP received — $port rebooting.');
        }
      }

      serial.close();
      return (true, 'RESET sent to $port — device rebooting.');
    } catch (e) {
      serial.close();
      return (false, 'RESET failed on $port: $e');
    }
  } catch (e) {
    return (false, 'Sahara reset error: $e');
  }
}
