import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// FIFO serialization also protects the machine-wide Qualcomm service.
class DeviceOperationQueue {
  static final shared = DeviceOperationQueue();
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }
}

/// Owns process lifetime, drains both pipes, and cancels timers on every exit.
class ManagedProcess {
  Process? _process;
  bool _cancelled = false;
  void Function()? _cancel;
  void abort() {
    _cancelled = true;
    _process?.kill();
    _cancel?.call();
  }

  Future<int> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Duration idleTimeout = const Duration(minutes: 10),
    Duration totalTimeout = const Duration(hours: 2),
    void Function(String line, bool stderr)? onLine,
  }) async {
    if (_cancelled) throw StateError('Operation cancelled');
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
    _process = process;
    final stopped = Completer<int>();
    Timer? idle;
    Timer? deadline;
    final subscriptions = <StreamSubscription<String>>[];
    final drains = <Future<void>>[];
    void fail(Object error, [StackTrace? stack]) {
      if (!stopped.isCompleted) stopped.completeError(error, stack);
      process.kill();
    }

    void activity() {
      idle?.cancel();
      idle = Timer(
        idleTimeout,
        () => fail(TimeoutException('No process output', idleTimeout)),
      );
    }

    void listen(Stream<List<int>> stream, bool isError) {
      final drained = Completer<void>();
      drains.add(drained.future);
      subscriptions.add(
        stream
            .map((bytes) {
              activity();
              return bytes;
            })
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(
              (line) {
                try {
                  if (!_cancelled) onLine?.call(line, isError);
                } catch (error, stack) {
                  fail(error, stack);
                }
              },
              onError: fail,
              onDone: () => drained.complete(),
            ),
      );
    }

    try {
      // Attach an error listener before timers or pipe handlers can complete it.
      final result = stopped.future;
      _cancel = () => fail(StateError('Operation cancelled'));
      listen(process.stdout, false);
      listen(process.stderr, true);
      activity();
      deadline = Timer(
        totalTimeout,
        () => fail(TimeoutException('Process deadline', totalTimeout)),
      );
      process.exitCode.then((code) {
        if (!stopped.isCompleted) stopped.complete(code);
      }, onError: fail);
      if (_cancelled) {
        process.kill();
        fail(StateError('Operation cancelled'));
      }
      final code = await result;
      // Allow the streams to deliver trailing output before returning.
      await Future.wait(drains).timeout(const Duration(seconds: 5));
      if (_cancelled) throw StateError('Operation cancelled');
      return code;
    } finally {
      idle?.cancel();
      deadline?.cancel();
      process.kill();
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      try {
        await process.exitCode.timeout(const Duration(seconds: 5));
      } finally {
        _process = null;
        _cancel = null;
      }
    }
  }
}

Future<ProcessResult> runDeviceCommand(
  String executable,
  List<String> arguments,
) async {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = await ManagedProcess().run(
    executable,
    arguments,
    idleTimeout: const Duration(seconds: 30),
    totalTimeout: const Duration(seconds: 60),
    onLine: (line, isError) => (isError ? err : out).writeln(line),
  );
  return ProcessResult(0, code, out.toString(), err.toString());
}

/// Called inside the shared queue; restore only a service that was running.
Future<T> withQualcommService<T>(
  Future<T> Function() action, {
  Future<ProcessResult> Function(String, List<String>) commandRunner =
      runDeviceCommand,
}) async {
  if (!Platform.isWindows) return action();
  final query = await commandRunner('sc.exe', ['query', 'qcmtusvc']);
  if (query.exitCode == 1060) return action(); // Service not installed.
  if (query.exitCode != 0) {
    throw StateError('Cannot query qcmtusvc: ${query.stderr}');
  }
  final wasRunning = RegExp(
    r'STATE\s*:\s*4\b',
  ).hasMatch(query.stdout.toString());
  final wasStopped = RegExp(
    r'STATE\s*:\s*1\b',
  ).hasMatch(query.stdout.toString());
  if (!wasRunning && !wasStopped) {
    throw StateError('qcmtusvc is changing state; retry later');
  }
  try {
    if (wasRunning) {
      final stop = await commandRunner('sc.exe', ['stop', 'qcmtusvc']);
      if (stop.exitCode != 0) {
        throw StateError('Cannot stop qcmtusvc: ${stop.stdout}');
      }
      var stopped = false;
      for (var i = 0; i < 20; i++) {
        final state = await commandRunner('sc.exe', ['query', 'qcmtusvc']);
        if (RegExp(r'STATE\s*:\s*1\b').hasMatch(state.stdout.toString())) {
          stopped = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (!stopped) throw TimeoutException('qcmtusvc did not stop');
    }
    return await action();
  } finally {
    if (wasRunning) {
      final result = await commandRunner('sc.exe', ['start', 'qcmtusvc']);
      if (result.exitCode != 0 && result.exitCode != 1056) {
        throw StateError('Cannot restore qcmtusvc: ${result.stdout}');
      }
    }
  }
}
