import 'request.dart';
import 'response.dart';

/// The core interface for components executing network requests.
abstract class SpidrClient {
  /// Sends the given [request] asynchronously and returns the [SpidrResponse].
  Future<SpidrResponse> send(SpidrRequest request);

  /// Closes the client, releasing any underlying resources.
  void close();
}
