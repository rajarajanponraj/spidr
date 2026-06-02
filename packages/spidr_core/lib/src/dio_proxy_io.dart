import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'request.dart';

/// Configures programmatic proxy settings on the Dio client for native platforms.
void configureDioProxy(Dio dio, SpidrRequest request) {
  final proxy = request.extra['proxy'] as String?;
  if (proxy != null && proxy.isNotEmpty) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (uri) {
          // returns e.g. "PROXY 127.0.0.1:8080" or "SOCKS5 127.0.0.1:1080"
          // We support standard PROXY format (Dio/HttpClient expects 'PROXY host:port')
          return 'PROXY $proxy';
        };
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
  }
}
