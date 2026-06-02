import 'package:meta/meta.dart';
import 'request.dart';

/// Represents the completed response retrieved from a SPIDR scrape.
@immutable
class SpidrResponse {
  /// The initiating request.
  final SpidrRequest request;

  /// The HTTP status code (e.g. 200).
  final int statusCode;

  /// The HTTP status explanation (e.g. 'OK').
  final String statusMessage;

  /// Multi-value response headers.
  final Map<String, List<String>> headers;

  /// The raw payload body bytes.
  final List<int> bodyBytes;

  /// The body decoded as a string.
  final String bodyString;

  /// The duration taken to execute the request.
  final Duration duration;

  /// Creates a new [SpidrResponse].
  const SpidrResponse({
    required this.request,
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.bodyBytes,
    required this.bodyString,
    required this.duration,
  });

  /// Helper getter to determine if the request succeeded.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
