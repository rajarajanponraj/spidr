/// Base class for all exceptions thrown by the SPIDR framework.
abstract class SpidrException implements Exception {
  /// The user-facing explanation of the exception.
  final String message;

  /// The underlying object/exception that triggered this failure, if any.
  final Object? cause;

  /// Creates a new [SpidrException].
  const SpidrException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'SpidrException: $message (Cause: $cause)';
    }
    return 'SpidrException: $message';
  }
}

/// Thrown when a requested framework capability is not supported on the current platform.
class UnsupportedCapabilityException extends SpidrException {
  /// Creates a new [UnsupportedCapabilityException].
  const UnsupportedCapabilityException(super.message, [super.cause]);
}

/// Thrown when request execution fails (e.g., timeout, network connection, proxy issues).
class SpidrNetworkException extends SpidrException {
  /// The HTTP status code returned, if any.
  final int? statusCode;

  /// Creates a new [SpidrNetworkException].
  const SpidrNetworkException(String message, {this.statusCode, Object? cause})
    : super(message, cause);
}

/// Thrown when parsing HTML/XML DOM structures fails.
class SpidrParseException extends SpidrException {
  /// Creates a new [SpidrParseException].
  const SpidrParseException(super.message, [super.cause]);
}

/// Thrown when a browser automation action fails.
class SpidrBrowserException extends SpidrException {
  /// Creates a new [SpidrBrowserException].
  const SpidrBrowserException(super.message, [super.cause]);
}
