import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as dom;
import 'element.dart';
import 'html_parser.dart';

/// Represents a persistent visual, behavioral, and structural fingerprint of a DOM element.
class ElementFingerprint {
  /// The HTML tag name of the element (e.g. 'div', 'button').
  final String tagName;

  /// List of CSS classes present on the element.
  final List<String> classes;

  /// Map of all attributes on the element (excluding the 'class' attribute).
  final Map<String, String> attributes;

  /// Calculated absolute XPath position of the element in the document.
  final String? xpath;

  /// Calculated CSS selector path of the element in the document.
  final String? cssSelector;

  /// List of HTML tag names of the element's direct siblings.
  final List<String> siblingTags;

  /// Hierarchical depth of the element in the document tree (0 from html root).
  final int depth;

  /// Pre-computed hash of the parent element's identifying characteristics.
  final String? parentHash;

  /// Creates a new [ElementFingerprint].
  const ElementFingerprint({
    required this.tagName,
    required this.classes,
    required this.attributes,
    this.xpath,
    this.cssSelector,
    required this.siblingTags,
    required this.depth,
    this.parentHash,
  });

  /// Serializes the fingerprint to a standard JSON-compatible Map.
  Map<String, dynamic> toJson() => {
        'tagName': tagName,
        'classes': classes,
        'attributes': attributes,
        'xpath': xpath,
        'cssSelector': cssSelector,
        'siblingTags': siblingTags,
        'depth': depth,
        'parentHash': parentHash,
      };

  /// Deserializes a fingerprint from a JSON-compatible Map.
  factory ElementFingerprint.fromJson(Map<String, dynamic> json) {
    return ElementFingerprint(
      tagName: json['tagName'] as String,
      classes: List<String>.from(json['classes'] as List? ?? const []),
      attributes: Map<String, String>.from(json['attributes'] as Map? ?? const {}),
      xpath: json['xpath'] as String?,
      cssSelector: json['cssSelector'] as String?,
      siblingTags: List<String>.from(json['siblingTags'] as List? ?? const []),
      depth: json['depth'] as int? ?? 0,
      parentHash: json['parentHash'] as String?,
    );
  }

  /// Calculates a SHA-256 hash of the fingerprint's properties for comparison and tracking.
  String get hash {
    final serialized = jsonEncode(toJson());
    return sha256.convert(utf8.encode(serialized)).toString();
  }

  /// Generates a fingerprint for the given [element].
  factory ElementFingerprint.capture(SpidrElement element) {
    if (element is HtmlSpidrElement) {
      final domElement = element.rawElement;
      return ElementFingerprint._fromDomElement(domElement);
    }
    
    // Fallback for simple elements that don't support full DOM traversal
    final classes = element.attributes['class']
            ?.split(RegExp(r'\s+'))
            .where((c) => c.isNotEmpty)
            .toList() ??
        const [];
    final attrs = Map<String, String>.from(element.attributes)..remove('class');
    return ElementFingerprint(
      tagName: element.tagName,
      classes: classes,
      attributes: attrs,
      siblingTags: const [],
      depth: 0,
    );
  }

  static ElementFingerprint _fromDomElement(dom.Element element) {
    final tagName = element.localName ?? '';
    final classes = element.classes.toList();
    final attributes = Map<String, String>.from(
      element.attributes.map((key, val) => MapEntry(key.toString(), val)),
    )..remove('class');

    final parent = element.parent;
    final siblingTags = <String>[];
    if (parent != null) {
      for (final child in parent.children) {
        if (child != element) {
          siblingTags.add(child.localName ?? '');
        }
      }
    }

    var depth = 0;
    String? parentHash;
    var current = element.parent;
    if (current != null) {
      parentHash = _hashDomElementSimple(current);
      while (current != null) {
        depth++;
        current = current.parent;
      }
    }

    final xpath = _calculateXPath(element);
    final cssSelector = _calculateCssSelector(element);

    return ElementFingerprint(
      tagName: tagName,
      classes: classes,
      attributes: attributes,
      xpath: xpath,
      cssSelector: cssSelector,
      siblingTags: siblingTags,
      depth: depth,
      parentHash: parentHash,
    );
  }

  static String _hashDomElementSimple(dom.Element element) {
    final data = {
      'tagName': element.localName ?? '',
      'classes': element.classes.toList(),
      'id': element.id,
    };
    return sha256.convert(utf8.encode(jsonEncode(data))).toString();
  }

  static String _calculateXPath(dom.Element element) {
    final segments = <String>[];
    var current = element;
    while (true) {
      final parent = current.parent;
      if (parent == null) {
        segments.insert(0, '${current.localName}');
        break;
      }
      
      var index = 1;
      for (final sibling in parent.children) {
        if (sibling == current) {
          break;
        }
        if (sibling.localName == current.localName) {
          index++;
        }
      }
      
      segments.insert(0, '${current.localName}[$index]');
      current = parent;
    }
    return '/${segments.join('/')}';
  }

  static String _calculateCssSelector(dom.Element element) {
    final id = element.id;
    if (id.isNotEmpty) {
      return '#$id';
    }
    
    final segments = <String>[];
    var current = element;
    while (true) {
      final name = current.localName ?? '';
      if (current.id.isNotEmpty) {
        segments.insert(0, '#${current.id}');
        break;
      }
      
      final parent = current.parent;
      if (parent == null) {
        segments.insert(0, name);
        break;
      }
      
      var index = 1;
      for (final sibling in parent.children) {
        if (sibling == current) {
          break;
        }
        if (sibling.localName == current.localName) {
          index++;
        }
      }
      
      if (index > 1) {
        segments.insert(0, '$name:nth-of-type($index)');
      } else {
        segments.insert(0, name);
      }
      
      current = parent;
    }
    return segments.join(' > ');
  }
}

/// Abstract persistence contract for storing and retrieving element fingerprints.
abstract class FingerprintStore {
  /// Saves the [fingerprint] associated with the identifier [key].
  Future<void> save(String key, ElementFingerprint fingerprint);

  /// Loads the [ElementFingerprint] associated with the identifier [key].
  /// Returns null if not found.
  Future<ElementFingerprint?> load(String key);
}

/// Volatile in-memory implementation of [FingerprintStore].
class MemoryFingerprintStore implements FingerprintStore {
  final Map<String, ElementFingerprint> _store = {};

  @override
  Future<void> save(String key, ElementFingerprint fingerprint) async {
    _store[key] = fingerprint;
  }

  @override
  Future<ElementFingerprint?> load(String key) async {
    return _store[key];
  }
}

/// Global registry holding the active [FingerprintStore] instance.
class SpidrFingerprintRegistry {
  /// The active [FingerprintStore].
  static FingerprintStore store = MemoryFingerprintStore();
}

/// Traverses all elements inside [rootElement] and returns the best matching candidate for [target].
/// Returns null if no candidate meets the threshold (0.6).
SpidrElement? findBestMatch(SpidrElement rootElement, ElementFingerprint target) {
  final allCandidates = <SpidrElement>[];

  void collect(SpidrElement element) {
    allCandidates.add(element);
    if (element is HtmlSpidrElement) {
      for (final child in element.rawElement.children) {
        collect(HtmlSpidrElement(child));
      }
    }
  }

  collect(rootElement);

  var bestScore = 0.0;
  SpidrElement? bestCandidate;

  for (final element in allCandidates) {
    final candidateFp = ElementFingerprint.capture(element);
    final score = calculateSimilarity(candidateFp, target);
    if (score > bestScore) {
      bestScore = score;
      bestCandidate = element;
    }
  }

  const confidenceThreshold = 0.6;
  if (bestScore >= confidenceThreshold) {
    return bestCandidate;
  }
  return null;
}

/// Calculates a similarity score between two fingerprints, returning a value between 0.0 and 1.0.
double calculateSimilarity(ElementFingerprint a, ElementFingerprint b) {
  var score = 0.0;
  var totalWeight = 0.0;

  // 1. Tag Name Match (Weight: 0.15)
  const tagWeight = 0.15;
  totalWeight += tagWeight;
  if (a.tagName == b.tagName) {
    score += tagWeight;
  }

  // 2. Classes Match (Weight: 0.15)
  const classWeight = 0.15;
  totalWeight += classWeight;
  if (a.classes.isNotEmpty || b.classes.isNotEmpty) {
    final intersect = a.classes.toSet().intersection(b.classes.toSet()).length;
    final union = a.classes.toSet().union(b.classes.toSet()).length;
    if (union > 0) {
      score += (intersect / union) * classWeight;
    }
  } else {
    score += classWeight;
  }

  // 3. Attributes Match (Weight: 0.20)
  const attrWeight = 0.20;
  totalWeight += attrWeight;
  final aKeys = a.attributes.keys.toSet();
  final bKeys = b.attributes.keys.toSet();
  if (aKeys.isNotEmpty || bKeys.isNotEmpty) {
    final commonKeys = aKeys.intersection(bKeys);
    final unionKeys = aKeys.union(bKeys);
    
    var matchingAttrs = 0;
    for (final key in commonKeys) {
      if (a.attributes[key] == b.attributes[key]) {
        matchingAttrs++;
      }
    }
    if (unionKeys.isNotEmpty) {
      score += (matchingAttrs / unionKeys.length) * attrWeight;
    }
  } else {
    score += attrWeight;
  }

  // 4. Sibling Tags Match (Weight: 0.10)
  const siblingWeight = 0.10;
  totalWeight += siblingWeight;
  if (a.siblingTags.isNotEmpty || b.siblingTags.isNotEmpty) {
    final intersect = a.siblingTags.toSet().intersection(b.siblingTags.toSet()).length;
    final union = a.siblingTags.toSet().union(b.siblingTags.toSet()).length;
    if (union > 0) {
      score += (intersect / union) * siblingWeight;
    }
  } else {
    score += siblingWeight;
  }

  // 5. Depth Match (Weight: 0.10)
  const depthWeight = 0.10;
  totalWeight += depthWeight;
  final depthDiff = (a.depth - b.depth).abs();
  if (depthDiff == 0) {
    score += depthWeight;
  } else {
    final penalty = depthDiff * 0.02;
    score += (depthWeight - penalty).clamp(0.0, depthWeight);
  }

  // 6. Parent Hash Match (Weight: 0.10)
  const parentWeight = 0.10;
  totalWeight += parentWeight;
  if (a.parentHash == b.parentHash && a.parentHash != null) {
    score += parentWeight;
  }

  // 7. XPath Match (Weight: 0.10)
  const xpathWeight = 0.10;
  totalWeight += xpathWeight;
  if (a.xpath == b.xpath && a.xpath != null) {
    score += xpathWeight;
  }

  // 8. CSS Selector Match (Weight: 0.10)
  const cssWeight = 0.10;
  totalWeight += cssWeight;
  if (a.cssSelector == b.cssSelector && a.cssSelector != null) {
    score += cssWeight;
  }

  return totalWeight > 0 ? (score / totalWeight) : 0.0;
}
