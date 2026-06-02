import 'dart:async';

/// Throttling helper enforcing requests-per-second and concurrency limits in SPIDR.
class SpidrRateLimiter {
  /// Maximum operations allowed per second across a specific domain.
  final double? maxRequestsPerSecond;

  /// Absolute minimum pause between request dispatches.
  final Duration? delayBetweenRequests;

  /// Maximum concurrent network transactions.
  final int maxConcurrentRequests;

  final Map<String, DateTime> _lastRequestTimes = {};
  int _activeRequests = 0;
  final List<Completer<void>> _concurrencyQueue = [];

  /// Creates a new [SpidrRateLimiter].
  SpidrRateLimiter({
    this.maxRequestsPerSecond,
    this.delayBetweenRequests,
    this.maxConcurrentRequests = 5,
  });

  /// Acquires a slot to dispatch a request to a given [domain].
  /// Delays execution asynchronously if bounds are exceeded.
  Future<void> acquire(String domain) async {
    // 1. Concurrency block checks
    while (_activeRequests >= maxConcurrentRequests) {
      final completer = Completer<void>();
      _concurrencyQueue.add(completer);
      await completer.future;
    }
    _activeRequests++;

    // 2. Inter-request timing delay checks
    final lastTime = _lastRequestTimes[domain];
    final now = DateTime.now();

    var requiredDelay = Duration.zero;

    if (delayBetweenRequests != null) {
      requiredDelay = delayBetweenRequests!;
    } else if (maxRequestsPerSecond != null && maxRequestsPerSecond! > 0) {
      requiredDelay = Duration(
        milliseconds: (1000 / maxRequestsPerSecond!).round(),
      );
    }

    if (lastTime != null && requiredDelay > Duration.zero) {
      final elapsed = now.difference(lastTime);
      final remaining = requiredDelay - elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }

    _lastRequestTimes[domain] = DateTime.now();
  }

  /// Releases the concurrency slot, waking up any queued requests.
  void release(String domain) {
    _activeRequests--;
    _lastRequestTimes[domain] = DateTime.now();
    if (_concurrencyQueue.isNotEmpty) {
      final completer = _concurrencyQueue.removeAt(0);
      completer.complete();
    }
  }
}
