import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'client.dart';
import 'cookie_jar.dart';
import 'exceptions.dart';
import 'middleware.dart';
import 'rate_limiter.dart';
import 'request.dart';
import 'response.dart';
import 'retry_policy.dart';

import 'dio_proxy_stub.dart'
    if (dart.library.io) 'dio_proxy_io.dart'
    if (dart.library.js_interop) 'dio_proxy_web.dart'
    if (dart.library.html) 'dio_proxy_web.dart';

/// Concrete implementation of [SpidrClient] using the robust cross-platform `Dio` package.
class DioSpidrClient implements SpidrClient {
  final dio.Dio _dio = dio.Dio();

  /// List of custom request/response middlewares.
  final List<SpidrMiddleware> middlewares;

  /// Custom cookie manager jar.
  final SpidrCookieJar cookieJar;

  /// Throttling rate limiter.
  final SpidrRateLimiter? rateLimiter;

  /// Failed attempt retry configurations.
  final RetryConfig retryConfig;

  /// Creates a new [DioSpidrClient] instance.
  DioSpidrClient({
    this.middlewares = const [],
    SpidrCookieJar? cookieJar,
    this.rateLimiter,
    this.retryConfig = const RetryConfig(),
  }) : cookieJar = cookieJar ?? SpidrCookieJar();

  @override
  Future<SpidrResponse> send(SpidrRequest request) async {
    final domain = request.url.host;
    if (rateLimiter != null) {
      await rateLimiter!.acquire(domain);
    }

    try {
      return await _executeWithRetries(request);
    } finally {
      if (rateLimiter != null) {
        rateLimiter!.release(domain);
      }
    }
  }

  Future<SpidrResponse> _executeWithRetries(SpidrRequest request) async {
    var attempts = 0;
    while (true) {
      attempts++;
      try {
        return await _executeOnce(request);
      } catch (error) {
        final shouldRetry = _shouldRetry(error, attempts);
        if (!shouldRetry) {
          if (error is SpidrException) rethrow;
          throw SpidrNetworkException(
            'Request dispatch failed: $error',
            cause: error,
          );
        }

        final delay = retryConfig.getDelay(attempts);
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
      }
    }
  }

  bool _shouldRetry(Object error, int attempt) {
    if (attempt > retryConfig.maxRetries) return false;

    if (retryConfig.shouldRetry != null) {
      return retryConfig.shouldRetry!(error);
    }

    if (error is SpidrNetworkException) {
      final status = error.statusCode;
      if (status != null && retryConfig.retryStatusCodes.contains(status)) {
        return true;
      }
    }

    if (error is dio.DioException) {
      final type = error.type;
      if (type == dio.DioExceptionType.connectionTimeout ||
          type == dio.DioExceptionType.sendTimeout ||
          type == dio.DioExceptionType.receiveTimeout ||
          type == dio.DioExceptionType.connectionError) {
        return true;
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null &&
          retryConfig.retryStatusCodes.contains(statusCode)) {
        return true;
      }
    }

    return false;
  }

  Future<SpidrResponse> _executeOnce(SpidrRequest request) async {
    // 1. Process Request Middlewares
    var currentRequest = request;
    for (final middleware in middlewares) {
      currentRequest = await middleware.onRequest(currentRequest);
    }

    // 2. Cookie Management
    final cookieHeader = cookieJar.getCookieHeader(currentRequest.url);
    final headers = Map<String, String>.from(currentRequest.headers);
    if (cookieHeader.isNotEmpty) {
      headers['Cookie'] = cookieHeader;
    }

    // 3. Configure Proxy
    configureDioProxy(_dio, currentRequest);

    // 4. Send execution
    final stopwatch = Stopwatch()..start();
    try {
      final options = dio.Options(
        method: currentRequest.method,
        headers: headers,
        sendTimeout: currentRequest.timeout,
        receiveTimeout: currentRequest.timeout,
        followRedirects: currentRequest.followRedirects,
        maxRedirects: currentRequest.maxRedirects,
        validateStatus: (status) => true, // resolve status code locally
        responseType: dio.ResponseType.bytes,
      );

      final dioResponse = await _dio.request<List<int>>(
        currentRequest.url.toString(),
        data: currentRequest.body,
        options: options,
      );

      stopwatch.stop();

      final bodyBytes = dioResponse.data ?? const <int>[];
      var bodyString = '';
      try {
        bodyString = utf8.decode(bodyBytes, allowMalformed: true);
      } catch (_) {}

      final responseHeaders = <String, List<String>>{};
      dioResponse.headers.forEach((name, values) {
        responseHeaders[name] = values;
      });

      final setCookies = responseHeaders['set-cookie'] ?? const [];
      if (setCookies.isNotEmpty) {
        cookieJar.saveFromResponse(currentRequest.url, setCookies);
      }

      final spidrResponse = SpidrResponse(
        request: currentRequest,
        statusCode: dioResponse.statusCode ?? 200,
        statusMessage: dioResponse.statusMessage ?? 'OK',
        headers: responseHeaders,
        bodyBytes: bodyBytes,
        bodyString: bodyString,
        duration: stopwatch.elapsed,
      );

      // 5. Process Response Middlewares
      var currentResponse = spidrResponse;
      for (final middleware in middlewares) {
        currentResponse = await middleware.onResponse(currentResponse);
      }

      final status = currentResponse.statusCode;
      if (status >= 400) {
        throw SpidrNetworkException(
          'HTTP request failed with status: $status ${currentResponse.statusMessage}',
          statusCode: status,
        );
      }

      return currentResponse;
    } on dio.DioException catch (e) {
      stopwatch.stop();
      throw SpidrNetworkException(
        'Dio network exception: ${e.message}',
        statusCode: e.response?.statusCode,
        cause: e,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is SpidrException) rethrow;
      throw SpidrNetworkException('HTTP execution failure: $e', cause: e);
    }
  }

  @override
  void close() {
    _dio.close(force: true);
  }
}
