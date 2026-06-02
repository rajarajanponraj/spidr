import 'dart:async';
import 'dart:convert';
import 'package:spidr_core/spidr_core.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';
import 'browser.dart';

/// Throws [UnsupportedCapabilityException] since web cannot spawn processes.
Future<SpidrBrowser> launchCdpBrowser({
  bool headless = true,
  List<String> args = const [],
  String? executablePath,
}) async {
  throw const UnsupportedCapabilityException(
    'Local browser process launching is not supported on Web environments.',
  );
}

/// Connects to a remote running browser instance over CDP WebSocket.
Future<SpidrBrowser> connectCdpBrowser(String wsUrl) async {
  try {
    final wip = await WipConnection.connect(wsUrl, onError: (err) {});
    return WebCdpBrowser(wip);
  } catch (e) {
    throw SpidrBrowserException(
      'Failed to connect to Chrome over CDP WebSocket: $e',
      e,
    );
  }
}

/// Helper to construct a page's WebSocket debugger URL from the browser's URL.
String _getWebSocketDebuggerUrl(String browserWsUrl, String targetId) {
  final uri = Uri.parse(browserWsUrl);
  if (uri.pathSegments.contains('browser')) {
    final segments = List<String>.from(uri.pathSegments);
    final idx = segments.indexOf('browser');
    segments[idx] = 'page';
    if (idx + 1 < segments.length) {
      segments[idx + 1] = targetId;
    } else {
      segments.add(targetId);
    }
    return uri.replace(pathSegments: segments).toString();
  }
  return uri.replace(path: '/devtools/page/$targetId').toString();
}

/// Web-specific CDP Browser orchestrator.
class WebCdpBrowser implements SpidrBrowser {
  final WipConnection _connection;

  /// Creates a new [WebCdpBrowser] instance.
  WebCdpBrowser(this._connection);

  Future<List<Map<String, dynamic>>> _getTargets() async {
    final response = await _connection.sendCommand('Target.getTargets');
    final result = response.result;
    if (result == null) return [];
    final targetInfos = result['targetInfos'] as List?;
    if (targetInfos == null) return [];
    return targetInfos.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<SpidrBrowserPage>> pages() async {
    final targets = await _getTargets();
    final pagesList = <SpidrBrowserPage>[];
    for (final t in targets) {
      final type = t['type'] as String;
      final targetId = t['targetId'] as String;
      if (type == 'page') {
        final wsUrl = _getWebSocketDebuggerUrl(_connection.url, targetId);
        final tabWip = await WipConnection.connect(wsUrl, onError: (err) {});
        pagesList.add(WebCdpBrowserPage(tabWip));
      }
    }
    return pagesList;
  }

  @override
  Future<SpidrBrowserPage> newPage() async {
    final targetId = await _connection.target.createTarget('about:blank');
    final wsUrl = _getWebSocketDebuggerUrl(_connection.url, targetId);
    final tabWip = await WipConnection.connect(wsUrl, onError: (err) {});
    return WebCdpBrowserPage(tabWip);
  }

  @override
  Future<void> close() async {
    try {
      await _connection.close();
    } catch (_) {}
  }
}

/// Web-specific CDP Browser Page wrapper.
class WebCdpBrowserPage implements SpidrBrowserPage {
  final WipConnection _tabConnection;
  SpidrResponse? _response;

  /// Creates a new [WebCdpBrowserPage] wrapping [_tabConnection].
  WebCdpBrowserPage(this._tabConnection);

  @override
  SpidrResponse get response {
    if (_response == null) {
      throw StateError('Page has not navigated to any URL yet.');
    }
    return _response!;
  }

  @override
  SpidrElement get root => HtmlSpidrPage(response).root;

  @override
  Uri get url => _response?.request.url ?? Uri.parse('about:blank');

  @override
  String get html => _response?.bodyString ?? '';

  @override
  SpidrElement? css(String selector) => root.css(selector);

  @override
  List<SpidrElement> cssAll(String selector) => root.cssAll(selector);

  @override
  SpidrElement? xpath(String expression) => root.xpath(expression);

  @override
  List<SpidrElement> xpathAll(String expression) => root.xpathAll(expression);

  @override
  Future<SpidrElement?> adaptive(String selector) async => css(selector);

  @override
  Future<T> extract<T>() async => throw UnimplementedError(
    'Adaptive extraction is not implemented in browser page.',
  );

  @override
  Future<SpidrPage> render({
    Duration? timeout,
    String? waitSelector,
    List<String> scriptTriggers = const [],
  }) async {
    if (waitSelector != null) {
      await waitFor(waitSelector);
    }
    for (final script in scriptTriggers) {
      await evaluate<dynamic>(script);
    }
    await _refreshResponse();
    return this;
  }

  Future<void> _refreshResponse() async {
    try {
      final bodyStr = await evaluate<String>(
        'document.documentElement.outerHTML',
      );
      _response = SpidrResponse(
        request: SpidrRequest(url: url),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: utf8.encode(bodyStr),
        bodyString: bodyStr,
        duration: Duration.zero,
      );
    } catch (_) {}
  }

  @override
  Future<SpidrResponse> goto(String url, {Duration? timeout}) async {
    await _tabConnection.page.enable();
    final loadFuture = _tabConnection.onNotification.firstWhere(
      (event) => event.method == 'Page.loadEventFired',
    );
    await _tabConnection.page.navigate(url);
    await loadFuture.timeout(timeout ?? const Duration(seconds: 30));

    _response = SpidrResponse(
      request: SpidrRequest(url: Uri.parse(url)),
      statusCode: 200,
      statusMessage: 'OK',
      headers: const {},
      bodyBytes: const [],
      bodyString: '',
      duration: Duration.zero,
    );

    await _refreshResponse();
    return _response!;
  }

  @override
  Future<void> click(String selector) async {
    await evaluate<void>('document.querySelector("$selector").click()');
    await _refreshResponse();
  }

  @override
  Future<void> type(String selector, String text) async {
    final escapedText = text.replaceAll('"', '\\"');
    await evaluate<void>('''
      (() => {
        const el = document.querySelector("$selector");
        el.value = "$escapedText";
        el.dispatchEvent(new Event("input", { bubbles: true }));
        el.dispatchEvent(new Event("change", { bubbles: true }));
      })()
    ''');
    await _refreshResponse();
  }

  @override
  Future<void> waitFor(dynamic selectorOrFunctionOrDuration) async {
    if (selectorOrFunctionOrDuration is Duration) {
      await Future<void>.delayed(selectorOrFunctionOrDuration);
    } else if (selectorOrFunctionOrDuration is String) {
      final completer = Completer<void>();
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        try {
          final exists = await evaluate<bool>(
            'document.querySelector("$selectorOrFunctionOrDuration") !== null',
          );
          if (exists) {
            timer.cancel();
            completer.complete();
          }
        } catch (_) {}
      });
      await completer.future;
    }
    await _refreshResponse();
  }

  @override
  Future<T> evaluate<T>(String expression) async {
    try {
      final result = await _tabConnection.runtime.evaluate(
        expression,
        returnByValue: true,
      );
      if (result.value == null) {
        return null as T;
      }
      return result.value as T;
    } catch (e) {
      throw SpidrBrowserException(
        'Evaluation failed for expression: $expression',
        e,
      );
    }
  }

  @override
  Future<List<int>> screenshot({String format = 'png', int? quality}) async {
    final response = await _tabConnection.sendCommand(
      'Page.captureScreenshot',
      {'format': format, if (quality != null) 'quality': quality},
    );
    final base64Data = response.result?['data'] as String;
    return base64.decode(base64Data);
  }
}
