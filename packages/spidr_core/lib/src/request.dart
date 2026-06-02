import 'package:meta/meta.dart';

/// Represents an HTTP or Browser navigation request in SPIDR.
@immutable
class SpidrRequest {
  /// The target URL for the request.
  final Uri url;

  /// The HTTP method to use (e.g. 'GET', 'POST'). Defaults to 'GET'.
  final String method;

  /// HTTP headers to include with the request.
  final Map<String, String> headers;

  /// Optional request body as raw bytes.
  final List<int>? body;

  /// Maximum time to wait for the request/navigation to complete.
  final Duration timeout;

  /// Maximum redirect hops.
  final int maxRedirects;

  /// Whether to automatically follow HTTP redirects.
  final bool followRedirects;

  /// Context metadata containing execution-specific properties (e.g., sessions, proxy instructions).
  final Map<String, dynamic> extra;

  /// Creates a new [SpidrRequest].
  const SpidrRequest({
    required this.url,
    this.method = 'GET',
    this.headers = const {},
    this.body,
    this.timeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
    this.followRedirects = true,
    this.extra = const {},
  });

  /// Creates a copy of this request with modified fields.
  SpidrRequest copyWith({
    Uri? url,
    String? method,
    Map<String, String>? headers,
    List<int>? body,
    Duration? timeout,
    int? maxRedirects,
    bool? followRedirects,
    Map<String, dynamic>? extra,
  }) {
    return SpidrRequest(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
      maxRedirects: maxRedirects ?? this.maxRedirects,
      followRedirects: followRedirects ?? this.followRedirects,
      extra: extra ?? this.extra,
    );
  }

  /// Serializes the request to a JSON-compatible Map.
  Map<String, dynamic> toJson() => {
        'url': url.toString(),
        'method': method,
        'headers': headers,
        'body': body,
        'timeout': timeout.inMilliseconds,
        'maxRedirects': maxRedirects,
        'followRedirects': followRedirects,
        'extra': extra,
      };

  /// Deserializes a request from a JSON-compatible Map.
  factory SpidrRequest.fromJson(Map<String, dynamic> json) => SpidrRequest(
        url: Uri.parse(json['url'] as String),
        method: json['method'] as String? ?? 'GET',
        headers: Map<String, String>.from(json['headers'] as Map? ?? const {}),
        body: (json['body'] as List?)?.cast<int>(),
        timeout: Duration(milliseconds: json['timeout'] as int? ?? 30000),
        maxRedirects: json['maxRedirects'] as int? ?? 5,
        followRedirects: json['followRedirects'] as bool? ?? true,
        extra: Map<String, dynamic>.from(json['extra'] as Map? ?? const {}),
      );
}
