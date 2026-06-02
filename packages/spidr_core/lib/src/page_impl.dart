import 'element.dart';
import 'page.dart';
import 'response.dart';

/// Basic implementation of [SpidrElement] used for stubs and fallback parsing.
class SimpleSpidrElement implements SpidrElement {
  @override
  final String tagName;

  @override
  final String text;

  @override
  final String html;

  @override
  final Map<String, String> attributes;

  /// Creates a new [SimpleSpidrElement].
  const SimpleSpidrElement({
    this.tagName = 'div',
    this.text = '',
    this.html = '',
    this.attributes = const {},
  });

  @override
  String? attribute(String name) => attributes[name];

  @override
  SpidrElement? css(String selector) => null;

  @override
  List<SpidrElement> cssAll(String selector) => const [];

  @override
  SpidrElement? xpath(String expression) => null;

  @override
  List<SpidrElement> xpathAll(String expression) => const [];
}

/// Basic implementation of [SpidrPage] used for stubs and fallback document wrappers.
class SimpleSpidrPage extends SpidrPage {
  @override
  final SpidrResponse response;

  @override
  final SpidrElement root;

  /// Creates a new [SimpleSpidrPage].
  SimpleSpidrPage(this.response, [SpidrElement? root])
    : root =
          root ??
          SimpleSpidrElement(
            text: response.bodyString,
            html: response.bodyString,
          );

  @override
  Future<SpidrElement?> adaptive(String selector) async => null;

  @override
  Future<T> extract<T>() async {
    throw UnimplementedError('AI extraction not implemented yet (Phase 14).');
  }
}
