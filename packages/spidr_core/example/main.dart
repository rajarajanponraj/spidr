import 'package:spidr_core/spidr_core.dart';

void main() {
  // Resolve platform capabilities at runtime
  final caps = SpidrCapabilities.current();
  print('SPIDR Platform Capabilities:');
  print(' - Supports Proxy: ${caps.supportsProxy}');
  print(' - Supports Local Browser Process: ${caps.supportsLocalBrowser}');
  print(' - Supports Remote CDP WebSocket: ${caps.supportsRemoteBrowser}');
  print(' - Supports Storage: ${caps.supportsStorage}');
  print(' - Supports Isolates: ${caps.supportsIsolates}');
}
