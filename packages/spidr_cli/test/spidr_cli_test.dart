import 'package:test/test.dart';
import 'package:spidr_cli/spidr_cli.dart';

void main() {
  group('SpidrCli Tests', () {
    test('run with empty args returns usage instructions', () async {
      final cli = SpidrCli();
      final output = await cli.run([]);
      expect(output, contains('Usage: spidr'));
      expect(output, contains('scrape'));
    });

    test('run with valid command returns execution log', () async {
      final cli = SpidrCli();
      final output = await cli.run(['scrape']);
      expect(output, contains('Executing scrape command...'));
    });

    test('run with unknown command returns warning', () async {
      final cli = SpidrCli();
      final output = await cli.run(['unknown_command']);
      expect(output, contains('Unknown command'));
    });
  });
}
