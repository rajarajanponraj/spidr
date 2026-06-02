import 'package:spidr_browser/spidr_browser.dart';

void main() async {
  try {
    print('Attempting to launch browser...');
    final browser = await SpidrBrowser.launch();
    print('Browser launched successfully!');
    final pages = await browser.pages();
    print('Open pages count: ${pages.length}');
    await browser.close();
    print('Browser closed successfully.');
  } catch (e) {
    print('Browser launch exception (expected in Phase 1):');
    print('  $e');
  }
}
