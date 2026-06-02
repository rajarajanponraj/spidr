import 'capabilities_stub.dart'
    if (dart.library.io) 'capabilities_io.dart'
    if (dart.library.js_interop) 'capabilities_web.dart'
    if (dart.library.html) 'capabilities_web.dart';

/// Exposes the platform capability profile of the current running host.
class SpidrCapabilities {
  /// Whether the platform supports raw socket-based proxy configuration (e.g. SOCKS5, HTTP proxies).
  final bool supportsProxy;

  /// Whether the platform supports spawning process-level local browser engines (e.g. Windows, macOS, Linux, Server).
  final bool supportsLocalBrowser;

  /// Whether the platform supports remote Chrome DevTools Protocol connections over WebSockets.
  final bool supportsRemoteBrowser;

  /// Whether the platform supports local database engines (like SQLite/Isar).
  final bool supportsStorage;

  /// Whether the platform supports standard isolates for concurrent parallel execution.
  final bool supportsIsolates;

  /// Creates a custom [SpidrCapabilities] instance.
  const SpidrCapabilities({
    required this.supportsProxy,
    required this.supportsLocalBrowser,
    required this.supportsRemoteBrowser,
    required this.supportsStorage,
    required this.supportsIsolates,
  });

  /// Evaluates current environment and resolves capabilities.
  factory SpidrCapabilities.current() => getPlatformCapabilities();

  @override
  String toString() {
    return 'SpidrCapabilities(supportsProxy: $supportsProxy, '
        'supportsLocalBrowser: $supportsLocalBrowser, '
        'supportsRemoteBrowser: $supportsRemoteBrowser, '
        'supportsStorage: $supportsStorage, '
        'supportsIsolates: $supportsIsolates)';
  }
}
