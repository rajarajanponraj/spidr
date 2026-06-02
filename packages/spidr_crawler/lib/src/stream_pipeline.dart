import 'dart:async';
import 'package:spidr_core/spidr_core.dart';

/// A custom [StreamTransformer] that executes conversion futures concurrently
/// up to a maximum [concurrency] limit.
class ConcurrentStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// The async operation running on each item.
  final Future<T> Function(S) convert;

  /// Maximum concurrent operations.
  final int concurrency;

  /// Creates a new [ConcurrentStreamTransformer].
  ConcurrentStreamTransformer(this.convert, {this.concurrency = 4}) {
    if (concurrency < 1) {
      throw ArgumentError.value(concurrency, 'concurrency', 'Must be at least 1.');
    }
  }

  @override
  Stream<T> bind(Stream<S> stream) {
    late StreamController<T> controller;
    late StreamSubscription<S> subscription;
    var activeCount = 0;
    var isDone = false;
    var isSubscriptionPaused = false;

    void resume() {
      if (activeCount < concurrency && isSubscriptionPaused) {
        isSubscriptionPaused = false;
        subscription.resume();
      }
    }

    void handleData(S data) {
      activeCount++;
      if (activeCount >= concurrency && !isSubscriptionPaused) {
        isSubscriptionPaused = true;
        subscription.pause();
      }

      convert(data).then((result) {
        controller.add(result);
      }).catchError((Object err, StackTrace stackTrace) {
        controller.addError(err, stackTrace);
      }).whenComplete(() {
        activeCount--;
        if (isDone && activeCount == 0) {
          controller.close();
        } else {
          resume();
        }
      });
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          handleData,
          onError: controller.addError,
          onDone: () {
            isDone = true;
            if (activeCount == 0) {
              controller.close();
            }
          },
        );
      },
      onPause: () => subscription.pause(),
      onResume: () => resume(),
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }
}

/// Helper that feeds a stream of requests into a concurrent executing pipeline.
class SpidrStreamExtractor {
  /// The HTTP client interface.
  final SpidrClient client;

  /// The concurrency limit.
  final int concurrency;

  /// Creates a new [SpidrStreamExtractor] wrapping [client] with [concurrency].
  SpidrStreamExtractor(this.client, {this.concurrency = 4});

  /// Binds the given [requests] stream to a concurrent executing pipeline.
  Stream<SpidrResponse> bind(Stream<SpidrRequest> requests) {
    return requests.transform(
      ConcurrentStreamTransformer<SpidrRequest, SpidrResponse>(
        (request) => client.send(request),
        concurrency: concurrency,
      ),
    );
  }
}
