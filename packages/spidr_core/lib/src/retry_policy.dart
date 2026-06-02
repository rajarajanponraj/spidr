import 'dart:math';

/// Strategies to compute delays between retry attempts.
enum BackoffStrategy {
  /// Increases delay in a linear sequence (e.g. 1s, 2s, 3s).
  linear,

  /// Increases delay exponentially (e.g. 1s, 2s, 4s, 8s).
  exponential,
}

/// Retry policy definitions for handling network failures or transient error responses.
class RetryConfig {
  /// Maximum number of times to retry a failed operation.
  final int maxRetries;

  /// Starting delay for the initial retry.
  final Duration initialDelay;

  /// Throttling progression method.
  final BackoffStrategy backoffStrategy;

  /// Status codes that warrant trigger retries (defaults to 500, 502, 503, 504).
  final Set<int> retryStatusCodes;

  /// Custom evaluation hook to check if an exception is retriable.
  final bool Function(Object error)? shouldRetry;

  /// Creates a new [RetryConfig].
  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffStrategy = BackoffStrategy.exponential,
    this.retryStatusCodes = const {500, 502, 503, 504},
    this.shouldRetry,
  });

  /// Calculates the backoff delay for the given [attempt].
  Duration getDelay(int attempt) {
    if (attempt <= 0) return Duration.zero;

    switch (backoffStrategy) {
      case BackoffStrategy.linear:
        return initialDelay * attempt;
      case BackoffStrategy.exponential:
        final factor = pow(2, attempt - 1);
        // Include a 0-20% random jitter factor to avoid synchronization thundering herds
        final jitter = Random().nextDouble() * 0.2 * factor;
        final totalFactor = factor + jitter;
        return Duration(
          milliseconds: (initialDelay.inMilliseconds * totalFactor).round(),
        );
    }
  }
}
