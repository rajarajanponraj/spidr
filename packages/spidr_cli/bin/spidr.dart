import 'dart:io';
import 'package:spidr_cli/src/cli.dart';

void main(List<String> args) async {
  final cli = SpidrCli();
  final result = await cli.run(args);
  stdout.writeln(result);
}
