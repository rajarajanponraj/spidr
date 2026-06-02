import 'package:spidr_storage/spidr_storage.dart';

void main() async {
  final storage = MemoryStorageAdapter();
  await storage.open();

  await storage.write('active_session_id', 'session_abc123');
  final session = await storage.read('active_session_id');
  print('SPIDR Session persisted successfully: $session');

  await storage.close();
}
