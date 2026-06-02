import 'browser.dart';

/// Launches a local browser process. Stub throws [UnsupportedError].
Future<SpidrBrowser> launchCdpBrowser({
  bool headless = true,
  List<String> args = const [],
  String? executablePath,
}) => throw UnsupportedError(
  'Process launching is not supported on this platform.',
);

/// Connects to a remote running browser instance over CDP WebSocket. Stub throws [UnsupportedError].
Future<SpidrBrowser> connectCdpBrowser(String wsUrl) => throw UnsupportedError(
  'CDP WebSocket connection is not supported on this platform.',
);
