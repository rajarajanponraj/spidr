import 'dart:io';

/// Resolves the absolute path to the local Chrome/Chromium installation.
class ChromeFinder {
  /// Locates Google Chrome executable on the host system.
  /// Throws [ProcessException] if no installation matches.
  static String find() {
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      final paths = [
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        if (localAppData != null)
          '$localAppData\\Google\\Chrome\\Application\\chrome.exe',
      ];
      for (final p in paths) {
        if (File(p).existsSync()) return p;
      }
    } else if (Platform.isMacOS) {
      const p = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
      if (File(p).existsSync()) return p;
    } else if (Platform.isLinux) {
      final paths = [
        '/usr/bin/google-chrome',
        '/usr/bin/chrome',
        '/usr/bin/chromium',
        '/usr/bin/chromium-browser',
      ];
      for (final p in paths) {
        if (File(p).existsSync()) return p;
      }
    }
    throw const ProcessException(
      'chrome',
      [],
      'Could not locate Google Chrome or Chromium executable in standard system directories.',
    );
  }
}
