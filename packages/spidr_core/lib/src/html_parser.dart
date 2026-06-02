import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'element.dart';
import 'page.dart';
import 'page_impl.dart';
import 'response.dart';
import 'xpath_evaluator.dart';

/// Concrete implementation of [SpidrElement] backed by `package:html` DOM Element.
class HtmlSpidrElement implements SpidrElement {
  final dom.Element _element;

  /// Exposes the underlying HTML DOM element.
  dom.Element get rawElement => _element;

  /// Creates a new [HtmlSpidrElement] wrapping the underlying dom [_element].
  HtmlSpidrElement(this._element);

  @override
  String get tagName => _element.localName ?? '';

  @override
  String get text => _element.text;

  @override
  String get html => _element.outerHtml;

  @override
  Map<String, String> get attributes =>
      _element.attributes.map((key, value) => MapEntry(key.toString(), value));

  @override
  String? attribute(String name) => _element.attributes[name];

  @override
  SpidrElement? css(String selector) {
    final el = _element.querySelector(selector);
    if (el == null) return null;
    return HtmlSpidrElement(el);
  }

  @override
  List<SpidrElement> cssAll(String selector) {
    return _element
        .querySelectorAll(selector)
        .map((e) => HtmlSpidrElement(e))
        .toList();
  }

  @override
  SpidrElement? xpath(String expression) {
    final nodes = SpidrXpath.evaluate(_element, expression);
    for (final node in nodes) {
      if (node is dom.Element) {
        return HtmlSpidrElement(node);
      }
    }
    return null;
  }

  @override
  List<SpidrElement> xpathAll(String expression) {
    final nodes = SpidrXpath.evaluate(_element, expression);
    final elements = <SpidrElement>[];
    for (final node in nodes) {
      if (node is dom.Element) {
        elements.add(HtmlSpidrElement(node));
      } else if (node is dom.Text) {
        elements.add(SimpleSpidrElement(tagName: '#text', text: node.text));
      }
    }
    return elements;
  }
}

/// Concrete implementation of [SpidrPage] executing CSS and XPath parsing.
class HtmlSpidrPage extends SpidrPage {
  @override
  final SpidrResponse response;

  late final dom.Document _document;
  late final HtmlSpidrElement _root;

  /// Creates a new [HtmlSpidrPage] parsing [response.bodyString].
  HtmlSpidrPage(this.response) {
    _document = parser.parse(response.bodyString);
    _root = HtmlSpidrElement(
      _document.documentElement ?? dom.Element.tag('html'),
    );
  }

  @override
  SpidrElement get root => _root;

  @override
  Future<SpidrElement?> adaptive(String selector) => SpidrPage.adaptiveHelper(this, selector);



  @override
  Future<T> extract<T>() async {
    throw UnimplementedError(
      'AI structural extraction is not implemented yet. Commencing in Phase 14.',
    );
  }
}
