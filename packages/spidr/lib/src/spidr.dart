import 'package:spidr_core/spidr_core.dart';
import 'package:spidr_browser/spidr_browser.dart';

/// The root orchestration facade for the SPIDR web scraping framework.
class Spidr {
  static final bool _initialized = _registerRenderer();

  static bool _registerRenderer() {
    SpidrRendererRegistry.register(_renderPage);
    return true;
  }

  /// Exposes the runtime environment platform capabilities.
  static SpidrCapabilities get capabilities {
    final _ = _initialized;
    return SpidrCapabilities.current();
  }

  static SpidrBrowser? _cachedBrowser;

  /// Performs a standardized HTTP request, returning the parsed HTML [SpidrPage].
  static Future<SpidrPage> get(String url) async {
    final _ = _initialized;
    final client = DioSpidrClient();
    try {
      final response = await client.send(SpidrRequest(url: Uri.parse(url)));
      return HtmlSpidrPage(response);
    } finally {
      client.close();
    }
  }

  /// Launches or connects to a CDP-driven automated Chrome browser instance.
  /// Uses capability matching to determine process launching vs socket forwarding.
  static Future<SpidrBrowser> chrome({bool headless = true}) async {
    final _ = _initialized;
    if (capabilities.supportsLocalBrowser) {
      return SpidrBrowser.launch(headless: headless);
    } else if (capabilities.supportsRemoteBrowser) {
      throw const UnsupportedCapabilityException(
        'Local browser process is not supported on this platform. '
        'Please utilize `SpidrBrowser.connect(wsUrl)` to interface with a remote CDP instance.',
      );
    } else {
      throw const UnsupportedCapabilityException(
        'Browser automation is entirely unsupported on this platform.',
      );
    }
  }

  /// Cleanly closes any cached browser processes managed by SPIDR.
  static Future<void> close() async {
    final _ = _initialized;
    if (_cachedBrowser != null) {
      await _cachedBrowser!.close();
      _cachedBrowser = null;
    }
  }

  static Future<SpidrPage> _renderPage(
    SpidrPage page, {
    Duration? timeout,
    String? waitSelector,
    List<String> scriptTriggers = const [],
  }) async {
    if (!capabilities.supportsLocalBrowser &&
        !capabilities.supportsRemoteBrowser) {
      throw const UnsupportedCapabilityException(
        'Browser automation is entirely unsupported on this platform.',
      );
    }

    if (_cachedBrowser == null) {
      if (capabilities.supportsLocalBrowser) {
        _cachedBrowser = await SpidrBrowser.launch(headless: true);
      } else {
        throw const UnsupportedCapabilityException(
          'Local browser process is not supported on this platform. '
          'Please utilize `SpidrBrowser.connect(wsUrl)` to interface with a remote CDP instance.',
        );
      }
    }

    final browserPage = await _cachedBrowser!.newPage();
    try {
      await browserPage.goto(page.url.toString(), timeout: timeout);

      if (waitSelector != null) {
        await browserPage.waitFor(waitSelector);
      }

      for (final script in scriptTriggers) {
        await browserPage.evaluate<dynamic>(script);
      }

      return browserPage;
    } catch (e) {
      throw SpidrBrowserException('Failed to render page: $e', e);
    }
  }
}
