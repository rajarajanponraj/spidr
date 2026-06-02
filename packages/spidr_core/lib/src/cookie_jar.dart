/// Represents a parsed HTTP Cookie structure inside SPIDR.
class SpidrCookie {
  /// Name identifier of the cookie.
  final String name;

  /// Content value of the cookie.
  final String value;

  /// Associated domain (e.g. 'example.com').
  final String? domain;

  /// Associated route path scope (e.g. '/api').
  final String? path;

  /// Absolute expiration timestamp.
  final DateTime? expires;

  /// Whether the cookie is inaccessible to client-side scripts.
  final bool httpOnly;

  /// Whether the cookie requires secure transport protocol (HTTPS).
  final bool secure;

  /// Creates a new [SpidrCookie] instance.
  const SpidrCookie({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expires,
    this.httpOnly = false,
    this.secure = false,
  });

  /// Serializes the cookie to a standard JSON-compatible Map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'domain': domain,
        'path': path,
        'expires': expires?.toIso8601String(),
        'httpOnly': httpOnly,
        'secure': secure,
      };

  /// Deserializes a cookie from a JSON-compatible Map.
  factory SpidrCookie.fromJson(Map<String, dynamic> json) {
    return SpidrCookie(
      name: json['name'] as String,
      value: json['value'] as String,
      domain: json['domain'] as String?,
      path: json['path'] as String?,
      expires: json['expires'] != null
          ? DateTime.parse(json['expires'] as String)
          : null,
      httpOnly: json['httpOnly'] as bool? ?? false,
      secure: json['secure'] as bool? ?? false,
    );
  }

  /// Evaluates whether the cookie expiration timestamp has passed.
  bool get isExpired {
    if (expires == null) return false;
    return DateTime.now().isAfter(expires!);
  }

  /// Parses a raw 'Set-Cookie' header value.
  factory SpidrCookie.parse(String cookieString, Uri requestUri) {
    final parts = cookieString.split(';').map((s) => s.trim()).toList();
    if (parts.isEmpty || !parts[0].contains('=')) {
      throw const FormatException('Invalid Set-Cookie header format');
    }

    final kv = parts[0].split('=');
    final name = kv[0];
    final value = kv.sublist(1).join('=');

    String? domain;
    String? path;
    DateTime? expires;
    bool httpOnly = false;
    bool secure = false;

    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      final partLower = part.toLowerCase();
      if (partLower == 'httponly') {
        httpOnly = true;
      } else if (partLower == 'secure') {
        secure = true;
      } else if (partLower.startsWith('domain=')) {
        domain = part.substring(7).trim();
      } else if (partLower.startsWith('path=')) {
        path = part.substring(5).trim();
      } else if (partLower.startsWith('expires=')) {
        final expiresStr = part.substring(8).trim();
        expires = _parseHttpDate(expiresStr);
      }
    }

    // Standard fallbacks if attributes are missing
    var resolvedDomain = domain;
    if (resolvedDomain != null && resolvedDomain.startsWith('.')) {
      resolvedDomain = resolvedDomain.substring(1);
    }

    return SpidrCookie(
      name: name,
      value: value,
      domain: resolvedDomain ?? requestUri.host,
      path: path ?? (requestUri.path.isEmpty ? '/' : requestUri.path),
      expires: expires,
      httpOnly: httpOnly,
      secure: secure,
    );
  }

  static DateTime? _parseHttpDate(String dateString) {
    try {
      final clean = dateString
          .replaceAll(RegExp(r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s*'), '')
          .replaceAll('GMT', '')
          .trim();

      final months = {
        'jan': '01',
        'feb': '02',
        'mar': '03',
        'apr': '04',
        'may': '05',
        'jun': '06',
        'jul': '07',
        'aug': '08',
        'sep': '09',
        'oct': '10',
        'nov': '11',
        'dec': '12',
      };

      // Match "09 Jun 2021 10:18:14"
      final regex = RegExp(
        r'^(\d{1,2})\s+([a-zA-Z]+)\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
      );
      final match = regex.firstMatch(clean);
      if (match != null) {
        final day = match.group(1)!.padLeft(2, '0');
        final monthStr = match.group(2)!.toLowerCase().substring(0, 3);
        final month = months[monthStr] ?? '01';
        final year = match.group(3)!;
        final hour = match.group(4)!;
        final minute = match.group(5)!;
        final second = match.group(6)!;
        return DateTime.parse('$year-$month-${day}T$hour:$minute:${second}Z');
      }
    } catch (_) {}
    return null;
  }
}

/// A platform-agnostic container managing, matching, and storing Cookies.
class SpidrCookieJar {
  final List<SpidrCookie> _cookies = [];

  /// Registers cookies extracted from incoming HTTP response headers.
  void saveFromResponse(Uri url, List<String> setCookieHeaders) {
    for (final header in setCookieHeaders) {
      try {
        final cookie = SpidrCookie.parse(header, url);
        _cookies.removeWhere(
          (c) =>
              c.name == cookie.name &&
              c.domain == cookie.domain &&
              c.path == cookie.path,
        );

        if (!cookie.isExpired) {
          _cookies.add(cookie);
        }
      } catch (_) {}
    }
  }

  /// Resolves the 'Cookie' header payload for outgoing requests.
  String getCookieHeader(Uri url) {
    final now = DateTime.now();
    _cookies.removeWhere((c) => c.expires != null && now.isAfter(c.expires!));

    final matched = _cookies.where((c) {
      final host = url.host;
      final cDomain = c.domain ?? '';
      final domainMatch = host == cDomain || host.endsWith('.$cDomain');
      if (!domainMatch) return false;

      final path = url.path.isEmpty ? '/' : url.path;
      final cPath = c.path ?? '/';
      final pathMatch = path.startsWith(cPath);
      if (!pathMatch) return false;

      if (c.secure && url.scheme != 'https') return false;

      return true;
    }).toList();

    if (matched.isEmpty) return '';
    return matched.map((c) => '${c.name}=${c.value}').join('; ');
  }

  /// Returns a read-only list of stored cookies.
  List<SpidrCookie> get all => List.unmodifiable(_cookies);

  /// Manually inserts a cookie into the jar, replacing any duplicate entries.
  void addCookie(SpidrCookie cookie) {
    _cookies.removeWhere(
      (c) =>
          c.name == cookie.name &&
          c.domain == cookie.domain &&
          c.path == cookie.path,
    );
    if (!cookie.isExpired) {
      _cookies.add(cookie);
    }
  }

  /// Discards all stored cookies.
  void clear() {
    _cookies.clear();
  }
}
