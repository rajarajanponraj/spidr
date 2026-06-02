import 'dart:io';
import 'capabilities.dart';

/// Resolves platform capabilities for VM (Desktop, Mobile, Server).
SpidrCapabilities getPlatformCapabilities() {
  final isDesktopOrServer =
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  return SpidrCapabilities(
    supportsProxy: true,
    supportsLocalBrowser: isDesktopOrServer,
    supportsRemoteBrowser: true,
    supportsStorage: true,
    supportsIsolates: true,
  );
}
