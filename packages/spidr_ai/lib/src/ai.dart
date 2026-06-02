import 'package:spidr_core/spidr_core.dart';

/// Base schema mapper representing target attributes to extract.
abstract class SchemaConfig {
  /// Converts the schema mapping properties to a standard JSON format.
  Map<String, dynamic> toJson();
}

/// The core interface for AI-powered scraper extensions.
abstract class AiExtractor implements SpidrPlugin {
  /// Extracts dynamic attributes from raw [html] source matching the [schema].
  Future<Map<String, dynamic>> extractJson(String html, {SchemaConfig? schema});

  /// Extracts structured data mapping from [html] into a typed Dart model [T].
  Future<T> extractModel<T>(
    String html,
    T Function(Map<String, dynamic> json) fromJson, {
    SchemaConfig? schema,
  });
}

/// Mock AI implementation for basic testing.
class MockAiExtractor implements AiExtractor {
  @override
  String get name => 'spidr_ai';

  @override
  void initialize(SpidrPluginRegistry registry) {}

  @override
  Future<Map<String, dynamic>> extractJson(
    String html, {
    SchemaConfig? schema,
  }) async {
    return {
      'extracted': true,
      'sourceLength': html.length,
      'status': 'mock_parsed',
    };
  }

  @override
  Future<T> extractModel<T>(
    String html,
    T Function(Map<String, dynamic> json) fromJson, {
    SchemaConfig? schema,
  }) async {
    final json = await extractJson(html, schema: schema);
    return fromJson(json);
  }
}
