import 'package:test/test.dart';
import 'package:spidr_ai/spidr_ai.dart';

class SampleModel {
  final bool extracted;
  final int sourceLength;

  SampleModel(this.extracted, this.sourceLength);

  factory SampleModel.fromJson(Map<String, dynamic> json) {
    return SampleModel(json['extracted'] as bool, json['sourceLength'] as int);
  }
}

void main() {
  group('MockAiExtractor Tests', () {
    test('extractJson returns mock map data', () async {
      final ai = MockAiExtractor();
      final data = await ai.extractJson('<html></html>');
      expect(data['extracted'], isTrue);
      expect(data['status'], equals('mock_parsed'));
    });

    test('extractModel deserializes model instances correctly', () async {
      final ai = MockAiExtractor();
      final model = await ai.extractModel<SampleModel>(
        '<html></html>',
        SampleModel.fromJson,
      );
      expect(model.extracted, isTrue);
      expect(model.sourceLength, equals(13));
    });
  });
}
