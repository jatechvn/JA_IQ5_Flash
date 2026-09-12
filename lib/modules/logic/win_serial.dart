// lib/modules/logic/win_serial.dart
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WinSerial {
  final String portName;
  int _handle = INVALID_HANDLE_VALUE;

  WinSerial(this.portName);

  bool get isOpen => _handle != INVALID_HANDLE_VALUE;

  /// Open serial port with settings.
  bool open({int baudrate = 115200, double timeoutSeconds = 1.0}) {
    if (isOpen) close();

    // COM ports >= 10 must be prefixed with \\.\ to open correctly on Windows
    final formattedPort = portName.startsWith(r'\\.\')
        ? portName
        : r'\\.\' + portName;
    final portNamePtr = formattedPort.toNativeUtf16();

    try {
      _handle = CreateFile(
        portNamePtr,
        GENERIC_READ | GENERIC_WRITE,
        0, // Exclusive access
        nullptr,
        OPEN_EXISTING,
        0, // Sync I/O
        0,
      );

      if (_handle == INVALID_HANDLE_VALUE) {
        return false;
      }

      // Configure timeouts
      final timeouts = calloc<COMMTIMEOUTS>();
      try {
        final timeoutMs = (timeoutSeconds * 1000).toInt();
        timeouts.ref.ReadIntervalTimeout = 0xFFFFFFFF;
        timeouts.ref.ReadTotalTimeoutMultiplier = 0;
        timeouts.ref.ReadTotalTimeoutConstant = timeoutMs;
        timeouts.ref.WriteTotalTimeoutMultiplier = 0;
        timeouts.ref.WriteTotalTimeoutConstant =
            2000; // 2s constant write timeout

        if (SetCommTimeouts(_handle, timeouts) == 0) {
          close();
          return false;
        }
      } finally {
        free(timeouts);
      }

      // Configure DCB settings (baudrate, 8N1)
      final dcb = calloc<DCB>();
      try {
        dcb.ref.DCBlength = sizeOf<DCB>();
        if (GetCommState(_handle, dcb) == 0) {
          close();
          return false;
        }

        dcb.ref.BaudRate = baudrate;
        dcb.ref.ByteSize = 8;
        dcb.ref.Parity = NOPARITY;
        dcb.ref.StopBits = ONESTOPBIT;

        // Enable fBinary (1), fDtrControl = DTR_CONTROL_ENABLE (16), fRtsControl = RTS_CONTROL_ENABLE (4096).
        // 1 + 16 + 4096 = 4113
        dcb.ref.bitfield = 4113;

        if (SetCommState(_handle, dcb) == 0) {
          close();
          return false;
        }

        // Force DTR and RTS High using EscapeCommFunction (SETDTR = 5, SETRTS = 3)
        EscapeCommFunction(_handle, 5); // SETDTR
        EscapeCommFunction(_handle, 3); // SETRTS
      } finally {
        free(dcb);
      }

      // Purge stale buffers on open
      purge();
      return true;
    } catch (_) {
      close();
      return false;
    } finally {
      free(portNamePtr);
    }
  }

  /// Close the serial port handle.
  void close() {
    if (isOpen) {
      CloseHandle(_handle);
      _handle = INVALID_HANDLE_VALUE;
    }
  }

  /// Read up to [maxBytes] from the serial port.
  Uint8List read(int maxBytes) {
    if (!isOpen) return Uint8List(0);

    final bytesToRead = calloc<DWORD>();
    final buffer = calloc<BYTE>(maxBytes);

    try {
      final success = ReadFile(_handle, buffer, maxBytes, bytesToRead, nullptr);

      final readCount = bytesToRead.value;
      if (success == 0 || readCount == 0) {
        return Uint8List(0);
      }

      final list = Uint8List(readCount);
      for (int i = 0; i < readCount; i++) {
        list[i] = buffer[i];
      }
      return list;
    } catch (_) {
      return Uint8List(0);
    } finally {
      free(bytesToRead);
      free(buffer);
    }
  }

  /// Write [data] bytes to the serial port. Returns the number of bytes written.
  int write(Uint8List data) {
    if (!isOpen) return 0;

    final bytesWritten = calloc<DWORD>();
    final buffer = calloc<BYTE>(data.length);

    try {
      // Copy data to FFI pointer memory using typed list (faster and safer)
      buffer.asTypedList(data.length).setAll(0, data);

      final success = WriteFile(
        _handle,
        buffer,
        data.length,
        bytesWritten,
        nullptr,
      );

      if (success == 0) {
        return 0;
      }
      return bytesWritten.value;
    } catch (_) {
      return 0;
    } finally {
      free(bytesWritten);
      free(buffer);
    }
  }

  /// Flush written data to the hardware (blocks until transmission complete).
  void flush() {
    // No-op for synchronous Windows virtual COM port handles.
    // Calling FlushFileBuffers on non-filesystem handles is unsupported by Win32
    // and can cause Qualcomm USB serial drivers to discard outbound packets.
  }

  /// Purge/discard pending input and output buffers.
  void purge() {
    if (!isOpen) return;
    PurgeComm(
      _handle,
      PURGE_TXABORT | PURGE_RXABORT | PURGE_TXCLEAR | PURGE_RXCLEAR,
    );
  }

  /// Change read timeout dynamically on the open handle.
  bool setTimeout(double timeoutSeconds) {
    if (!isOpen) return false;
    final timeouts = calloc<COMMTIMEOUTS>();
    try {
      final timeoutMs = (timeoutSeconds * 1000).toInt();
      timeouts.ref.ReadIntervalTimeout = 0xFFFFFFFF;
      timeouts.ref.ReadTotalTimeoutMultiplier = 0;
      timeouts.ref.ReadTotalTimeoutConstant = timeoutMs;
      timeouts.ref.WriteTotalTimeoutMultiplier = 0;
      timeouts.ref.WriteTotalTimeoutConstant = 2000;

      return SetCommTimeouts(_handle, timeouts) != 0;
    } catch (_) {
      return false;
    } finally {
      free(timeouts);
    }
  }
}
