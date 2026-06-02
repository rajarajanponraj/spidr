import 'package:dio/dio.dart';
import 'request.dart';

/// Ignores programmatic proxy settings on the Web due to browser sandbox restrictions.
void configureDioProxy(Dio dio, SpidrRequest request) {
  // No-op for Web platform
}
