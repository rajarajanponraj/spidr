import 'package:spidr/spidr.dart';

void main() {
  final caps = Spidr.capabilities;
  print('SPIDR umbrella package initialized successfully.');
  print('Resolved capabilities:');
  print('  - Proxy: ${caps.supportsProxy}');
  print('  - Local Browser: ${caps.supportsLocalBrowser}');
}
