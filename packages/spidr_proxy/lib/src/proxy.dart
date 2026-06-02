import 'package:spidr_core/spidr_core.dart';

/// Supported networking proxy protocols.
enum ProxyProtocol {
  /// Unencrypted HTTP protocol.
  http,

  /// SSL/TLS Encrypted HTTPS protocol.
  https,

  /// Socket Secure (SOCKS5) protocol.
  socks5,
}

/// Represents connection attributes of a proxy server.
class ProxyInfo {
  /// Proxy IP or domain hostname.
  final String host;

  /// Connection port.
  final int port;

  /// The protocol format used by the proxy.
  final ProxyProtocol protocol;

  /// Optional username for authentication.
  final String? username;

  /// Optional password for authentication.
  final String? password;

  /// Priority weighting for selection strategies (defaults to 1.0).
  final double weight;

  /// Creates a new [ProxyInfo].
  const ProxyInfo({
    required this.host,
    required this.port,
    this.protocol = ProxyProtocol.http,
    this.username,
    this.password,
    this.weight = 1.0,
  });

  /// Resolves the proxy address string (including authentication).
  String get authority {
    if (username != null && password != null) {
      return '$username:$password@$host:$port';
    }
    return '$host:$port';
  }

  @override
  String toString() => '${protocol.name}://$authority';
}

/// Proxy rotation strategies.
enum ProxyStrategy {
  /// Selects a proxy at random.
  random,

  /// Iterates sequentially.
  roundRobin,

  /// Selects based on probability weights.
  weighted,

  /// Persists a single proxy identifier with a specific session key.
  sticky,
}

/// Manages collections of proxies and selection strategies.
abstract class ProxyPool implements SpidrPlugin {
  /// Returns a read-only list of active proxies.
  List<ProxyInfo> get proxies;

  /// Submits a proxy to the pool.
  Future<void> add(ProxyInfo proxy);

  /// Discards a proxy from the pool.
  Future<void> remove(ProxyInfo proxy);

  /// Resolves the next proxy to use.
  Future<ProxyInfo?> next({
    String? sessionId,
    ProxyStrategy strategy = ProxyStrategy.random,
  });
}

/// Base proxy pool implementation.
class BasicProxyPool implements ProxyPool {
  final List<ProxyInfo> _proxies = [];
  int _roundRobinIndex = 0;
  final Map<String, ProxyInfo> _stickySessions = {};

  @override
  String get name => 'spidr_proxy';

  @override
  void initialize(SpidrPluginRegistry registry) {}

  @override
  List<ProxyInfo> get proxies => List.unmodifiable(_proxies);

  @override
  Future<void> add(ProxyInfo proxy) async {
    if (!_proxies.contains(proxy)) {
      _proxies.add(proxy);
    }
  }

  @override
  Future<void> remove(ProxyInfo proxy) async {
    _proxies.remove(proxy);
  }

  @override
  Future<ProxyInfo?> next({
    String? sessionId,
    ProxyStrategy strategy = ProxyStrategy.random,
  }) async {
    if (_proxies.isEmpty) return null;

    if (strategy == ProxyStrategy.sticky && sessionId != null) {
      if (_stickySessions.containsKey(sessionId)) {
        return _stickySessions[sessionId];
      }
      final proxy = _selectProxy(strategy);
      if (proxy != null) {
        _stickySessions[sessionId] = proxy;
      }
      return proxy;
    }

    return _selectProxy(strategy);
  }

  ProxyInfo? _selectProxy(ProxyStrategy strategy) {
    switch (strategy) {
      case ProxyStrategy.roundRobin:
        final proxy = _proxies[_roundRobinIndex];
        _roundRobinIndex = (_roundRobinIndex + 1) % _proxies.length;
        return proxy;
      case ProxyStrategy.weighted:
        // Stub implementation defaults to returning first available
        return _proxies.first;
      case ProxyStrategy.random:
      default:
        return (List<ProxyInfo>.from(_proxies)..shuffle()).first;
    }
  }
}
