import 'dart:async';
import 'dart:isolate';
import 'package:spidr_core/spidr_core.dart';

/// Command message type sent to the worker isolate.
class _WorkerCommand {
  final Map<String, dynamic> requestJson;
  final SendPort replyPort;

  const _WorkerCommand({required this.requestJson, required this.replyPort});
}

/// Represents the execution results returned from a worker isolate.
class WorkerResult {
  /// The resulting response, if successful.
  final SpidrResponse? response;

  /// Error details, if execution failed.
  final String? error;

  /// Whether the execution completed successfully.
  bool get isSuccess => error == null;

  /// Creates a new [WorkerResult] representation.
  const WorkerResult({this.response, this.error});
}

class _ActiveWorker {
  final Isolate isolate;
  final SendPort sendPort;
  bool isBusy = false;

  _ActiveWorker({required this.isolate, required this.sendPort});
}

/// A persistent pool of Dart Isolates used to execute scraping network requests in parallel.
class SpidrWorkerPool {
  /// The pool size (number of background isolates).
  final int size;

  final List<_ActiveWorker> _workers = [];
  final List<Completer<_ActiveWorker>> _waitingQueue = [];
  bool _isDisposed = false;

  /// Creates a new [SpidrWorkerPool] with configured isolate [size].
  SpidrWorkerPool({this.size = 4});

  /// Spawns and initializes all worker isolates.
  Future<void> start() async {
    if (_isDisposed) throw StateError('Worker pool has already been disposed.');
    if (_workers.isNotEmpty) return;

    for (var i = 0; i < size; i++) {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(_workerEntry, receivePort.sendPort);
      final sendPort = await receivePort.first as SendPort;
      _workers.add(_ActiveWorker(isolate: isolate, sendPort: sendPort));
    }
  }

  /// Executes a [SpidrRequest] on an available background isolate worker.
  Future<WorkerResult> execute(SpidrRequest request) async {
    if (_isDisposed) throw StateError('Worker pool has already been disposed.');
    if (_workers.isEmpty) {
      throw StateError('Worker pool is not started. Call start() first.');
    }

    final worker = await _getAvailableWorker();
    worker.isBusy = true;

    final responsePort = ReceivePort();
    worker.sendPort.send(_WorkerCommand(
      requestJson: request.toJson(),
      replyPort: responsePort.sendPort,
    ));

    final resultData = await responsePort.first as Map<String, dynamic>;
    responsePort.close();

    worker.isBusy = false;
    _releaseWorker(worker);

    if (resultData['success'] == true) {
      final responseMap = resultData['response'] as Map<String, dynamic>;
      return WorkerResult(response: SpidrResponse.fromJson(responseMap));
    } else {
      return WorkerResult(error: resultData['error'] as String);
    }
  }

  /// Shuts down all active isolates.
  Future<void> dispose() async {
    _isDisposed = true;
    for (final worker in _workers) {
      worker.isolate.kill(priority: Isolate.beforeNextEvent);
    }
    _workers.clear();
    for (final completer in _waitingQueue) {
      completer.completeError(StateError('Worker pool was disposed.'));
    }
    _waitingQueue.clear();
  }

  Future<_ActiveWorker> _getAvailableWorker() async {
    for (final worker in _workers) {
      if (!worker.isBusy) return worker;
    }
    final completer = Completer<_ActiveWorker>();
    _waitingQueue.add(completer);
    return completer.future;
  }

  void _releaseWorker(_ActiveWorker worker) {
    if (_isDisposed) return;
    if (_waitingQueue.isNotEmpty) {
      final next = _waitingQueue.removeAt(0);
      next.complete(worker);
    }
  }

  static void _workerEntry(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    final client = DioSpidrClient();

    receivePort.listen((message) async {
      final cmd = message as _WorkerCommand;
      try {
        final request = SpidrRequest.fromJson(cmd.requestJson);
        final response = await client.send(request);

        cmd.replyPort.send({
          'success': true,
          'response': response.toJson(),
        });
      } catch (e) {
        cmd.replyPort.send({
          'success': false,
          'error': e.toString(),
        });
      }
    });
  }
}
