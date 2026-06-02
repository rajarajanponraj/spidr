import 'package:spidr_cli/spidr_cli.dart';

void main() async {
  final cli = SpidrCli();
  final result = await cli.run(['crawl']);
  print('CLI Command Output Example:');
  print('  $result');
}
