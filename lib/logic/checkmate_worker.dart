import 'dart:async';
import 'dart:isolate';

import 'checkmate_isolate.dart';

/// A persistent background isolate that handles checkmate computation requests.
///
/// Unlike [compute()], which spawns a fresh isolate on every call (costing
/// 150–400 ms on Android), [CheckmateWorker] spawns the isolate **once** at
/// construction and keeps it alive for the duration of the game. Each
/// [check] call sends a request over a [SendPort] and awaits the reply —
/// no spawn overhead after the first frame.
class CheckmateWorker {
  late final Isolate _isolate;
  late final SendPort _sendPort;
  late final ReceivePort _receivePort;

  /// Completer used to surface replies from the worker isolate to awaiting
  /// [check] callers. Only one checkmate check runs at a time.
  Completer<bool>? _pendingCompleter;

  bool _disposed = false;

  CheckmateWorker._();

  /// Spawns the isolate and performs the two-way handshake.
  /// Completes once the worker is ready to accept requests.
  static Future<CheckmateWorker> create() async {
    final worker = CheckmateWorker._();
    await worker._init();
    return worker;
  }

  Future<void> _init() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _workerEntry,
      _receivePort.sendPort,
      debugName: 'CheckmateWorker',
    );

    // The first message from the isolate is its own SendPort.
    final completer = Completer<SendPort>();
    _receivePort.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message as SendPort);
      } else {
        // Subsequent messages are bool results for pending checkmate checks.
        _pendingCompleter?.complete(message as bool);
        _pendingCompleter = null;
      }
    });
    _sendPort = await completer.future;
  }

  /// Sends a checkmate-check request to the background isolate.
  ///
  /// [data] must be the map produced by [serializeBoardForCheckmate].
  /// Returns `true` if the position is checkmate/stalemate for the given player.
  Future<bool> check(Map<String, dynamic> data) async {
    if (_disposed) return false;
    assert(_pendingCompleter == null,
        'Concurrent checkmate checks are not supported');
    _pendingCompleter = Completer<bool>();
    _sendPort.send(data);
    return _pendingCompleter!.future;
  }

  /// Terminates the background isolate. Call this when the game ends or the
  /// controller is discarded.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _receivePort.close();
    _isolate.kill(priority: Isolate.beforeNextEvent);
    _pendingCompleter?.complete(false);
    _pendingCompleter = null;
  }
}

// ── Isolate entry point (top-level — required by Isolate.spawn) ────────────

void _workerEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  // Send the worker's own SendPort back to the main isolate so it can send
  // requests.
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    final data = message as Map<String, dynamic>;
    final result = checkmateIsolateEntry(data);
    mainSendPort.send(result);
  });
}
