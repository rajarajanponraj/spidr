import 'element.dart';
import 'exceptions.dart';
import 'response.dart';

typedef PageRenderer =
    Future<SpidrPage> Function(
      SpidrPage page, {
      Duration? timeout,
      String? waitSelector,
      List<String> scriptTriggers,
    });

/// A global registry that decoupled browser packages can use to register
/// their page rendering engines.
class SpidrRendererRegistry {
  static PageRenderer? _renderer;

  /// Registers the page rendering delegate function.
  static void register(PageRenderer renderer) {
    _renderer = renderer;
  }

  /// The currently registered page rendering delegate, if any.
  static PageRenderer? get renderer => _renderer;
}

/// Represents a parsed page document, either from a raw HTTP response or a browser window.
abstract class SpidrPage {
  /// The network response that was used to load this page.
  SpidrResponse get response;

  /// The root document element of the page (typically the '<html>' element).
  SpidrElement get root;

  /// The current URL of the page.
  Uri get url => response.request.url;

  /// The raw HTML contents of the page source.
  String get html => response.bodyString;

  /// Evaluates a CSS selector against the root element and returns the first match.
  SpidrElement? css(String selector) => root.css(selector);

  /// Evaluates a CSS selector against the root element and returns all matching elements.
  List<SpidrElement> cssAll(String selector) => root.cssAll(selector);

  /// Evaluates an XPath expression against the root element and returns the first match.
  SpidrElement? xpath(String expression) => root.xpath(expression);

  /// Evaluates an XPath expression against the root element and returns all matching elements.
  List<SpidrElement> xpathAll(String expression) => root.xpathAll(expression);

  /// Locates elements using self-healing capabilities if the standard selector fails.
  /// Resolves the selector based on historical visual, behavioral, and structural fingerprints.
  Future<SpidrElement?> adaptive(String selector);

  /// Automatically extracts structured, typed data schemas from the page.
  /// Leverages dynamic AST maps or registered AI models to construct instance of [T].
  Future<T> extract<T>();

  /// Promotes a static page into a fully rendered dynamic page by executing
  /// its JavaScript inside a headless browser engine.
  ///
  /// Throws [UnsupportedCapabilityException] if browser automation is not supported.
  Future<SpidrPage> render({
    Duration? timeout,
    String? waitSelector,
    List<String> scriptTriggers = const [],
  }) {
    final renderer = SpidrRendererRegistry.renderer;
    if (renderer == null) {
      throw const UnsupportedCapabilityException(
        'Rendering engine is not registered. Ensure the `spidr_browser` package is '
        'imported and configured, or use the main `spidr` facade.',
      );
    }
    return renderer(
      this,
      timeout: timeout,
      waitSelector: waitSelector,
      scriptTriggers: scriptTriggers,
    );
  }
}
