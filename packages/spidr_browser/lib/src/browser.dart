import 'cdp_browser_stub.dart'
    if (dart.library.io) 'cdp_browser_io.dart'
    if (dart.library.js_interop) 'cdp_browser_web.dart'
    if (dart.library.html) 'cdp_browser_web.dart';

import 'package:spidr_core/spidr_core.dart';

/// Entry interface for orchestrating Chrome DevTools Protocol (CDP) automated browsers.
abstract class SpidrBrowser {
  /// Launches a local browser process. Throws [UnsupportedCapabilityException] if the capability is missing.
  static Future<SpidrBrowser> launch({
    bool headless = true,
    List<String> args = const [],
    String? executablePath,
  }) {
    try {
      return launchCdpBrowser(
        headless: headless,
        args: args,
        executablePath: executablePath,
      );
    } on UnsupportedError catch (e) {
      throw UnsupportedCapabilityException(
        e.message ?? 'Process launching not supported.',
      );
    }
  }

  /// Connects to a remote running browser instance over CDP WebSocket.
  static Future<SpidrBrowser> connect(String wsUrl) {
    try {
      return connectCdpBrowser(wsUrl);
    } on UnsupportedError catch (e) {
      throw UnsupportedCapabilityException(
        e.message ?? 'WebSocket connection not supported.',
      );
    }
  }

  /// Lists all pages/tabs currently open in the browser context.
  Future<List<SpidrBrowserPage>> pages();

  /// Creates a new page (tab) in the browser.
  Future<SpidrBrowserPage> newPage();

  /// Closes the browser connection and terminates the browser process, if locally spawned.
  Future<void> close();
}

/// Abstract wrapper exposing automation page capabilities.
abstract class SpidrBrowserPage implements SpidrPage {
  /// Navigates the page to a specified URL and awaits page load completion.
  Future<SpidrResponse> goto(String url, {Duration? timeout});

  /// Simulates a mouse click event on the first element matching the CSS [selector].
  Future<void> click(String selector);

  /// Types the given [text] input into the element matching the CSS [selector].
  Future<void> type(String selector, String text);

  /// Pauses execution. Accepts a [Duration] for fixed wait, a [String] selector to wait for visibility,
  /// or a JavaScript string function to resolve truthy.
  Future<void> waitFor(dynamic selectorOrFunctionOrDuration);

  /// Evaluates a JavaScript [expression] in the browser page context and returns the result.
  Future<T> evaluate<T>(String expression);

  /// Captures a screenshot of the current page viewport and returns the raw image bytes.
  Future<List<int>> screenshot({String format = 'png', int? quality});

  /// Captures the complete browser page session context (cookies, localStorage, IndexedDB).
  Future<SpidrSession> saveSession(String sessionId);

  /// Restores the complete browser page session context (cookies, localStorage, IndexedDB).
  Future<void> restoreSession(SpidrSession session);
}
