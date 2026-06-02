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

  /// Serializes the response to a JSON-compatible Map.
  Map<String, dynamic> toJson() => {
        'request': request.toJson(),
        'statusCode': statusCode,
        'statusMessage': statusMessage,
        'headers': headers,
        'bodyBytes': bodyBytes,
        'bodyString': bodyString,
        'duration': duration.inMilliseconds,
      };

  /// Deserializes a response from a JSON-compatible Map.
  factory SpidrResponse.fromJson(Map<String, dynamic> json) => SpidrResponse(
        request: SpidrRequest.fromJson(json['request'] as Map<String, dynamic>),
        statusCode: json['statusCode'] as int,
        statusMessage: json['statusMessage'] as String? ?? '',
        headers: (json['headers'] as Map? ?? const {}).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List)),
        ),
        bodyBytes: List<int>.from(json['bodyBytes'] as List? ?? const []),
        bodyString: json['bodyString'] as String? ?? '',
        duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      );
}
