import 'package:html/dom.dart' as dom;

/// Represents a parsed step configuration within an XPath expression path query.
class XpathStep {
  /// Target tag name to search (e.g. 'div', 'p'). '*' represents wildcards.
  final String tagName;

  /// Whether the query searches through all sub-descendant trees (equivalent to '//').
  final bool isDescendant;

  /// Optional attribute key filter name (e.g. 'class', 'href').
  final String? attrName;

  /// Optional attribute value filter string matching.
  final String? attrValue;

  /// Optional absolute inner text string matching filter condition.
  final String? textEquals;

  /// Optional substring inner text matching filter condition.
  final String? textContains;

  /// Optional attribute selector for dynamic value extraction (e.g. '@href').
  final String? extractAttribute;

  /// Creates a new [XpathStep] configuration.
  const XpathStep({
    required this.tagName,
    this.isDescendant = false,
    this.attrName,
    this.attrValue,
    this.textEquals,
    this.textContains,
    this.extractAttribute,
  });
}

/// A lightweight, custom XPath parser and selector evaluator walking standard HTML DOM trees.
class SpidrXpath {
  /// Evaluates an [xpath] query string against a base DOM [root] node.
  /// Yields matching elements or text nodes.
  static List<dom.Node> evaluate(dom.Node root, String xpath) {
    final steps = parse(xpath);
    if (steps.isEmpty) return const [];

    var currentNodes = <dom.Node>[root];
    for (final step in steps) {
      final nextNodes = <dom.Node>[];
      for (final node in currentNodes) {
        nextNodes.addAll(_matchStep(node, step));
      }
      currentNodes = nextNodes;
      if (currentNodes.isEmpty) break;
    }
    return currentNodes;
  }

  /// Parses a raw [xpath] query string into a structured sequence of [XpathStep]s.
  static List<XpathStep> parse(String xpath) {
    if (xpath.isEmpty) return const [];

    final normalized = xpath.replaceAll('//', '/__/');
    final parts = normalized.split('/');

    final steps = <XpathStep>[];
    var nextIsDescendant = false;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) {
        if (i == 0 && xpath.startsWith('//')) {
          nextIsDescendant = true;
        }
        continue;
      }

      if (part == '__') {
        nextIsDescendant = true;
        continue;
      }

      if (part.startsWith('@')) {
        final attr = part.substring(1);
        steps.add(
          XpathStep(
            tagName: '',
            isDescendant: nextIsDescendant,
            extractAttribute: attr,
          ),
        );
        nextIsDescendant = false;
        continue;
      }

      final bracketStart = part.indexOf('[');
      var tagName = part;
      String? attrName;
      String? attrValue;
      String? textEquals;
      String? textContains;

      if (bracketStart != -1 && part.endsWith(']')) {
        tagName = part.substring(0, bracketStart).trim();
        final predicate = part
            .substring(bracketStart + 1, part.length - 1)
            .trim();

        if (predicate.startsWith('@')) {
          final eqIdx = predicate.indexOf('=');
          if (eqIdx != -1) {
            attrName = predicate.substring(1, eqIdx).trim();
            var val = predicate.substring(eqIdx + 1).trim();
            if ((val.startsWith('"') && val.endsWith('"')) ||
                (val.startsWith("'") && val.endsWith("'"))) {
              val = val.substring(1, val.length - 1);
            }
            attrValue = val;
          } else {
            attrName = predicate.substring(1).trim();
          }
        } else if (predicate.startsWith('text()=')) {
          var val = predicate.substring(7).trim();
          if ((val.startsWith('"') && val.endsWith('"')) ||
              (val.startsWith("'") && val.endsWith("'"))) {
            val = val.substring(1, val.length - 1);
          }
          textEquals = val;
        } else if (predicate.startsWith('contains(text(),')) {
          final startQuote = predicate.indexOf(RegExp('["\']'));
          final endQuote = predicate.lastIndexOf(RegExp('["\']'));
          if (startQuote != -1 && endQuote != -1 && endQuote > startQuote) {
            textContains = predicate.substring(startQuote + 1, endQuote);
          }
        }
      }

      steps.add(
        XpathStep(
          tagName: tagName,
          isDescendant: nextIsDescendant,
          attrName: attrName,
          attrValue: attrValue,
          textEquals: textEquals,
          textContains: textContains,
        ),
      );

      nextIsDescendant = false;
    }

    return steps;
  }

  static List<dom.Node> _matchStep(dom.Node node, XpathStep step) {
    final matches = <dom.Node>[];

    if (step.extractAttribute != null) {
      if (node is dom.Element) {
        final val = node.attributes[step.extractAttribute!];
        if (val != null) {
          matches.add(dom.Text(val));
        }
      }
      return matches;
    }

    final candidates = <dom.Node>[];
    if (step.isDescendant) {
      _collectDescendants(node, candidates);
    } else {
      candidates.addAll(node.nodes);
    }

    for (final candidate in candidates) {
      if (candidate is! dom.Element) continue;

      if (step.tagName != '*' &&
          step.tagName.toLowerCase() != candidate.localName?.toLowerCase()) {
        continue;
      }

      if (step.attrName != null) {
        if (!candidate.attributes.containsKey(step.attrName!)) continue;
        if (step.attrValue != null &&
            candidate.attributes[step.attrName!] != step.attrValue) {
          continue;
        }
      }

      if (step.textEquals != null && candidate.text.trim() != step.textEquals) {
        continue;
      }

      if (step.textContains != null &&
          !candidate.text.contains(step.textContains!)) {
        continue;
      }

      matches.add(candidate);
    }

    return matches;
  }

  static void _collectDescendants(dom.Node node, List<dom.Node> result) {
    for (final child in node.nodes) {
      result.add(child);
      _collectDescendants(child, result);
    }
  }
}
