/// Represents a strongly-typed, abstract wrapper around a parsed DOM element.
abstract class SpidrElement {
  /// The HTML tag name of the element (e.g. 'div', 'h1').
  String get tagName;

  /// The text content enclosed within this element, stripped of HTML markup.
  String get text;

  /// The raw inner/outer HTML content of the element.
  String get html;

  /// Map of all attributes defined on this element.
  Map<String, String> get attributes;

  /// Looks up a specific attribute by its case-insensitive [name].
  String? attribute(String name);

  /// Selects the first descendant element matching the CSS [selector].
  /// Returns null if no match is found.
  SpidrElement? css(String selector);

  /// Selects all descendant elements matching the CSS [selector].
  List<SpidrElement> cssAll(String selector);

  /// Selects the first descendant element matching the XPath [expression].
  /// Returns null if no match is found.
  SpidrElement? xpath(String expression);

  /// Selects all descendant elements matching the XPath [expression].
  List<SpidrElement> xpathAll(String expression);
}
