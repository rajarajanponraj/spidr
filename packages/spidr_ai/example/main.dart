import 'package:spidr_ai/spidr_ai.dart';

class ScrapedInfo {
  final bool extracted;
  final String status;

  ScrapedInfo({required this.extracted, required this.status});

  factory ScrapedInfo.fromJson(Map<String, dynamic> json) {
    return ScrapedInfo(
      extracted: json['extracted'] as bool,
      status: json['status'] as String,
    );
  }
}

void main() async {
  final ai = MockAiExtractor();
  final model = await ai.extractModel<ScrapedInfo>(
    '<div>Product Card</div>',
    ScrapedInfo.fromJson,
  );
  print('SPIDR AI Extraction Result:');
  print('  - Extracted: ${model.extracted}');
  print('  - Parse Status: ${model.status}');
}
