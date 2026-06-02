import 'package:spidr_browser/spidr_browser.dart';

void main() async {
  try {
    print('Attempting to launch browser...');
    await SpidrBrowser.launch();
  } catch (e) {
    print('Browser launch exception (expected in Phase 1):');
    print('  $e');
  }
}
