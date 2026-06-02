import 'request.dart';
import 'response.dart';

/// Middleware hook interface for intercepting requests and responses in SPIDR.
abstract class SpidrMiddleware {
  /// Base constructor.
  const SpidrMiddleware();

  /// Intercepts and potentially alters an outgoing [SpidrRequest] before it is dispatched.
  Future<SpidrRequest> onRequest(SpidrRequest request) async => request;

  /// Intercepts and potentially alters an incoming [SpidrResponse] before it is returned to the caller.
  Future<SpidrResponse> onResponse(SpidrResponse response) async => response;
}
