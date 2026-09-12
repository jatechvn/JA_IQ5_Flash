// lib/modules/logic/device_manager.dart
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../constants.dart';
import '../utils.dart';
import 'win_serial.dart';
import 'sahara.dart';

class DeviceInfo {
  final String port;
  final String description;
  final String hwid;
  final String serialNumber;

  // Sahara HELLO pre-captured details
  int saharaVersion = 2;
  int saharaVersionSup = 1;
  int saharaMode = 0;
  bool saharaHelloOk = false;

  DeviceInfo({
    required this.port,
    required this.description,
    required this.hwid,
    required this.serialNumber,
  });

  String get displayName => '$port  (Qualcomm EDL)';

  @override
  bool operator ==(Object other) => other is DeviceInfo && other.port == port;

  @override
  int get hashCode => port.hashCode;
}

class AdbDevice {
  final String serial;
  final String
  state; // "device", "recovery", "sideload", "unauthorized", "fastboot"
  final String model;
  final bool isFastboot;

  AdbDevice({
    required this.serial,
    required this.state,
    required this.model,
    required this.isFastboot,
  });

  String get display {
    if (isFastboot) {
      return 'FASTBOOT  $serial';
    }
    final m = model.isNotEmpty ? ' ($model)' : '';
    return 'ADB  $serial$m  [$state]';
  }
}

class DeviceManager {
  final void Function(DeviceInfo)? onDeviceAdded;
  final void Function(String port)? onDeviceRemoved;
  final void Function(List<AdbDevice>)? onAdbDevicesChanged;

  final Map<String, DeviceInfo> _knownEdl = {};
  List<AdbDevice> _knownAdb = [];
  Future<void>? _pendingPoll;
  bool _disposed = false;

  void dispose() {
    _disposed = true;
  }

  DeviceManager({
    this.onDeviceAdded,
    this.onDeviceRemoved,
    this.onAdbDevicesChanged,
  });

  Map<String, DeviceInfo> get knownEdl => _knownEdl;
  List<AdbDevice> get knownAdb => _knownAdb;

  /// Perform WMI + Registry scan to find currently connected EDL (VID 05C6, PID 9008) devices.
  List<DeviceInfo> scanEdlDevices() {
    final edlPorts = <DeviceInfo>[];
    if (!Platform.isWindows) return edlPorts;

    try {
      final activePorts = _getActiveComPorts();
      if (activePorts.isEmpty) return edlPorts;

      final edlPortNames = _getEdlPorts(activePorts);
      for (final port in edlPortNames) {
        edlPorts.add(
          DeviceInfo(
            port: port,
            description: 'Qualcomm HS-USB QDLoader 9008',
            hwid: 'USB\\VID_05C6&PID_9008',
            serialNumber: '',
          ),
        );
      }
    } catch (_) {}
    return edlPorts;
  }

  /// Query standard serial ports from Registry.
  List<String> _getActiveComPorts() {
    final ports = <String>[];
    final phKey = calloc<HKEY>();
    final subKey = 'HARDWARE\\DEVICEMAP\\SERIALCOMM'.toNativeUtf16();

    try {
      final status = RegOpenKeyEx(
        HKEY_LOCAL_MACHINE,
        subKey,
        0,
        KEY_READ,
        phKey,
      );

      if (status != ERROR_SUCCESS) return ports;

      final hKey = phKey.value;
      final valueName = calloc<WCHAR>(16383).cast<Utf16>();
      final valueNameLen = calloc<DWORD>();
      final data = calloc<BYTE>(16383);
      final dataLen = calloc<DWORD>();
      final type = calloc<DWORD>();

      int index = 0;
      while (true) {
        valueNameLen.value = 16383;
        dataLen.value = 16383;

        final result = RegEnumValue(
          hKey,
          index,
          valueName,
          valueNameLen,
          nullptr,
          type,
          data,
          dataLen,
        );

        if (result == ERROR_NO_MORE_ITEMS) break;
        if (result == ERROR_SUCCESS) {
          if (type.value == REG_SZ) {
            final port = data.cast<Utf16>().toDartString();
            ports.add(port);
          }
        }
        index++;
      }

      RegCloseKey(hKey);
      free(valueName);
      free(valueNameLen);
      free(data);
      free(dataLen);
      free(type);
    } catch (_) {
    } finally {
      free(phKey);
      free(subKey);
    }
    return ports;
  }

  /// Check active ports against USB registered Qualcomm EDL Device Parameters.
  List<String> _getEdlPorts(List<String> activePorts) {
    final edlPorts = <String>[];
    final phKey = calloc<HKEY>();
    final subKey = 'SYSTEM\\CurrentControlSet\\Enum\\USB\\VID_05C6&PID_9008'
        .toNativeUtf16();

    try {
      final status = RegOpenKeyEx(
        HKEY_LOCAL_MACHINE,
        subKey,
        0,
        KEY_READ,
        phKey,
      );

      if (status != ERROR_SUCCESS) return edlPorts;

      final hKey = phKey.value;
      final instanceName = calloc<WCHAR>(256).cast<Utf16>();
      final instanceNameLen = calloc<DWORD>();

      int index = 0;
      while (true) {
        instanceNameLen.value = 256;
        final result = RegEnumKeyEx(
          hKey,
          index,
          instanceName,
          instanceNameLen,
          nullptr,
          nullptr,
          nullptr,
          nullptr,
        );

        if (result == ERROR_NO_MORE_ITEMS) break;
        if (result == ERROR_SUCCESS) {
          final instName = instanceName.toDartString();
          final devParamsKey = calloc<HKEY>();
          final devParamsPath =
              'SYSTEM\\CurrentControlSet\\Enum\\USB\\VID_05C6&PID_9008\\$instName\\Device Parameters'
                  .toNativeUtf16();

          final dpStatus = RegOpenKeyEx(
            HKEY_LOCAL_MACHINE,
            devParamsPath,
            0,
            KEY_READ,
            devParamsKey,
          );

          if (dpStatus == ERROR_SUCCESS) {
            final dpKey = devParamsKey.value;
            final portNameVal = 'PortName'.toNativeUtf16();
            final data = calloc<BYTE>(256);
            final dataLen = calloc<DWORD>()..value = 256;
            final type = calloc<DWORD>();

            final qStatus = RegQueryValueEx(
              dpKey,
              portNameVal,
              nullptr,
              type,
              data,
              dataLen,
            );

            if (qStatus == ERROR_SUCCESS && type.value == REG_SZ) {
              final port = data.cast<Utf16>().toDartString();
              if (activePorts.contains(port)) {
                edlPorts.add(port);
              }
            }

            RegCloseKey(dpKey);
            free(portNameVal);
            free(data);
            free(dataLen);
            free(type);
          }
          free(devParamsKey);
          free(devParamsPath);
        }
        index++;
      }

      RegCloseKey(hKey);
      free(instanceName);
      free(instanceNameLen);
    } catch (_) {
    } finally {
      free(phKey);
      free(subKey);
    }
    return edlPorts;
  }

  /// Poll currently connected hardware devices.
  Future<void> poll() {
    if (_disposed) return Future.value();
    return _pendingPoll ??= _poll().whenComplete(() => _pendingPoll = null);
  }

  Future<void> _poll() async {
    // 1. Scan EDL Ports
    final currentEdl = {for (var d in scanEdlDevices()) d.port: d};

    // Check newly connected ports
    for (final entry in currentEdl.entries) {
      final port = entry.key;
      final dev = entry.value;

      if (!_knownEdl.containsKey(port)) {
        // Stop qcmtusvc and try pre-capturing Sahara HELLO
        await _captureSaharaHello(dev);
        if (_disposed) return;
        _knownEdl[port] = dev;
        if (onDeviceAdded != null) {
          onDeviceAdded!(dev);
        }
      }
    }

    // Check disconnected ports
    final removedPorts = _knownEdl.keys
        .where((p) => !currentEdl.containsKey(p))
        .toList();
    for (final port in removedPorts) {
      _knownEdl.remove(port);
      if (onDeviceRemoved != null) {
        onDeviceRemoved!(port);
      }
    }

    // 2. Scan ADB / Fastboot Devices
    final adbDevices = await _scanAdbFastboot();
    if (_disposed) return;
    _knownAdb = adbDevices;
    if (onAdbDevicesChanged != null) {
      onAdbDevicesChanged!(adbDevices);
    }
  }

  /// Stops service and captures Sahara HELLO packets.
  Future<void> _captureSaharaHello(DeviceInfo dev) async {
    // 1. Stop service
    await stopQualcommService();

    final serial = WinSerial(dev.port);
    // Open port and read with short timeout
    if (serial.open(baudrate: 115200, timeoutSeconds: 1.5)) {
      try {
        final raw = serial.read(48);
        if (raw.length >= 24) {
          final view = ByteData.sublistView(raw);
          final cmd = view.getUint32(0, Endian.little);
          if (cmd == saharaHello) {
            dev.saharaVersion = view.getUint32(8, Endian.little);
            dev.saharaVersionSup = view.getUint32(12, Endian.little);
            dev.saharaMode = view.getUint32(20, Endian.little);
            dev.saharaHelloOk = true;
          }
        }
      } catch (_) {
      } finally {
        serial.close();
      }
    }
  }

  /// Execute commands to list ADB and Fastboot serial details.
  Future<List<AdbDevice>> _scanAdbFastboot() async {
    final list = <AdbDevice>[];

    // 1. Scan ADB devices
    try {
      final res = await Process.run(adbExePath, ['devices', '-l']);
      if (res.exitCode == 0) {
        final lines = LineSplitter.split(res.stdout.toString());
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty ||
              line.startsWith('List of devices attached') ||
              line.startsWith('*')) {
            continue;
          }
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final serial = parts[0];
            final state = parts[1];

            // Extract model from line e.g. "model:Xiaomi_12"
            String model = '';
            final match = RegExp(r'model:(\S+)').firstMatch(line);
            if (match != null) {
              model = match.group(1)!.replaceAll('_', ' ');
            }
            list.add(
              AdbDevice(
                serial: serial,
                state: state,
                model: model,
                isFastboot: false,
              ),
            );
          }
        }
      }
    } catch (_) {}

    // 2. Scan Fastboot devices
    try {
      final res = await Process.run(fastbootExePath, ['devices']);
      if (res.exitCode == 0) {
        final lines = LineSplitter.split(res.stdout.toString());
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          final parts = line.split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            final serial = parts[0];
            list.add(
              AdbDevice(
                serial: serial,
                state: 'fastboot',
                model: '',
                isFastboot: true,
              ),
            );
          }
        }
      }
    } catch (_) {}

    return list;
  }
}
