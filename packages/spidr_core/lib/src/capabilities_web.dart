import 'capabilities.dart';

/// Resolves platform capabilities for the Web.
SpidrCapabilities getPlatformCapabilities() {
  return const SpidrCapabilities(
    supportsProxy: false,
    supportsLocalBrowser: false,
    supportsRemoteBrowser:
        true, // Websockets can connect to remote CDP instances
    supportsStorage: true, // Web IndexedDB
    supportsIsolates: false, // Browser doesn't support raw Dart Isolates
  );
}
