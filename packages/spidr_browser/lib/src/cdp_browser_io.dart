import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:spidr_core/spidr_core.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';
import 'browser.dart';
import 'chrome_finder.dart';

/// Spawns a local Chrome process and attaches a CDP connection.
Future<SpidrBrowser> launchCdpBrowser({
  bool headless = true,
  List<String> args = const [],
  String? executablePath,
}) async {
  final path = executablePath ?? ChromeFinder.find();

  // Find an open port (default to 9222 or search)
  const port = 9222;

  final process = await Process.start(path, [
    if (headless) '--headless',
    '--remote-debugging-port=$port',
    '--disable-gpu',
    '--no-first-run',
    '--no-sandbox',
    ...args,
  ]);

  // Await process initialization
  await Future<void>.delayed(const Duration(milliseconds: 1000));

  try {
    final resp = await http.get(
      Uri.parse('http://localhost:$port/json/version'),
    );
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final wsUrl = json['webSocketDebuggerUrl'] as String;

    return await connectCdpBrowser(wsUrl, process);
  } catch (e) {
    process.kill();
    throw SpidrBrowserException(
      'Failed to handshake with launched Chrome process: $e',
      e,
    );
  }
}

/// Establishes connection to an existing Chrome process over CDP WebSocket.
Future<SpidrBrowser> connectCdpBrowser(String wsUrl, [Process? process]) async {
  try {
    final wip = await WipConnection.connect(wsUrl, onError: (err) {});
    return IoCdpBrowser(wip, process);
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

/// VM-specific CDP Browser orchestrator.
class IoCdpBrowser implements SpidrBrowser {
  final WipConnection _connection;
  final Process? _process;

  /// Creates a new [IoCdpBrowser] instance.
  IoCdpBrowser(this._connection, this._process);

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
        pagesList.add(IoCdpBrowserPage(tabWip));
      }
    }
    return pagesList;
  }

  @override
  Future<SpidrBrowserPage> newPage() async {
    final targetId = await _connection.target.createTarget('about:blank');
    final wsUrl = _getWebSocketDebuggerUrl(_connection.url, targetId);
    final tabWip = await WipConnection.connect(wsUrl, onError: (err) {});
    return IoCdpBrowserPage(tabWip);
  }

  @override
  Future<void> close() async {
    try {
      await _connection.close();
    } catch (_) {}
    if (_process != null) {
      _process.kill();
    }
  }
}

/// VM-specific CDP Browser Page wrapper.
class IoCdpBrowserPage implements SpidrBrowserPage {
  final WipConnection _tabConnection;
  SpidrResponse? _response;

  /// Creates a new [IoCdpBrowserPage] wrapping [_tabConnection].
  IoCdpBrowserPage(this._tabConnection);

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
  Future<SpidrElement?> adaptive(String selector) => SpidrPage.adaptiveHelper(this, selector);



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
        awaitPromise: true,
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

  @override
  Future<SpidrSession> saveSession(String sessionId) async {
    // 1. Get browser cookies
    await _tabConnection.sendCommand('Network.enable');
    final cookiesResponse = await _tabConnection.sendCommand('Network.getCookies');
    final cookiesList = cookiesResponse.result?['cookies'] as List? ?? const [];
    final cookies = cookiesList.map((c) => Map<String, dynamic>.from(c as Map)).toList();

    // 2. Get local storage
    String localStorageJson = '{}';
    try {
      localStorageJson = await evaluate<String?>('JSON.stringify(localStorage)') ?? '{}';
    } catch (_) {}
    final localStorage = Map<String, String>.from(jsonDecode(localStorageJson) as Map);

    // 3. Get IndexedDB database dump
    String indexedDbJson = '{}';
    try {
      indexedDbJson = await evaluate<String?>('''
        (async () => {
          if (!window.indexedDB || !window.indexedDB.databases) return "{}";
          const dbs = await window.indexedDB.databases();
          const result = {};
          for (const dbInfo of dbs) {
            if (!dbInfo.name) continue;
            const db = await new Promise((resolve, reject) => {
              const req = window.indexedDB.open(dbInfo.name, dbInfo.version);
              req.onsuccess = () => resolve(req.result);
              req.onerror = () => reject(req.error);
            });
            const dbData = {};
            for (const storeName of db.objectStoreNames) {
              const tx = db.transaction(storeName, 'readonly');
              const store = tx.objectStore(storeName);
              const records = await new Promise((resolve) => {
                const req = store.getAll();
                req.onsuccess = () => resolve(req.result);
              });
              const keys = await new Promise((resolve) => {
                const req = store.getAllKeys();
                req.onsuccess = () => resolve(req.result);
              });
              const storeRecords = {};
              for (let i = 0; i < keys.length; i++) {
                storeRecords[String(keys[i])] = records[i];
              }
              dbData[storeName] = storeRecords;
            }
            db.close();
            result[dbInfo.name] = dbData;
          }
          return JSON.stringify(result);
        })()
      ''') ?? '{}';
    } catch (_) {}
    final parsed = jsonDecode(indexedDbJson) as Map;
    final indexedDb = <String, String>{};
    parsed.forEach((key, value) {
      indexedDb[key.toString()] = jsonEncode(value);
    });

    return SpidrSession(
      sessionId: sessionId,
      cookies: cookies,
      localStorage: localStorage,
      indexedDb: indexedDb,
    );
  }

  @override
  Future<void> restoreSession(SpidrSession session) async {
    // 1. Set browser cookies
    await _tabConnection.sendCommand('Network.enable');
    await _tabConnection.sendCommand('Network.clearBrowserCookies');
    for (final cMap in session.cookies) {
      await _tabConnection.sendCommand('Network.setCookie', {
        'name': cMap['name'],
        'value': cMap['value'],
        'domain': cMap['domain'],
        'path': cMap['path'],
        if (cMap['secure'] != null) 'secure': cMap['secure'],
        if (cMap['httpOnly'] != null) 'httpOnly': cMap['httpOnly'],
        if (cMap['sameSite'] != null) 'sameSite': cMap['sameSite'],
        if (cMap['expires'] != null) 'expires': cMap['expires'],
      });
    }

    // 2. Set local storage
    if (session.localStorage.isNotEmpty) {
      final escapedStorage = jsonEncode(session.localStorage);
      try {
        await evaluate<void>('''
          (() => {
            const data = $escapedStorage;
            localStorage.clear();
            for (const k in data) {
              localStorage.setItem(k, data[k]);
            }
          })()
        ''');
      } catch (_) {}
    }

    // 3. Set IndexedDB database dump
    if (session.indexedDb.isNotEmpty) {
      final escapedDb = jsonEncode(session.indexedDb);
      try {
        await evaluate<void>('''
          (async () => {
            const dbsData = $escapedDb;
            if (!window.indexedDB) return;
            for (const dbName in dbsData) {
              const dbData = typeof dbsData[dbName] === 'string' ? JSON.parse(dbsData[dbName]) : dbsData[dbName];
              const db = await new Promise((resolve, reject) => {
                const req = window.indexedDB.open(dbName);
                req.onsuccess = () => resolve(req.result);
                req.onerror = () => reject(req.error);
              });
              
              let activeDb = db;
              let version = db.version;
              let needsUpgrade = false;
              for (const storeName in dbData) {
                if (!db.objectStoreNames.contains(storeName)) {
                  needsUpgrade = true;
                  break;
                }
              }
              
              if (needsUpgrade) {
                db.close();
                activeDb = await new Promise((resolve, reject) => {
                  const req = window.indexedDB.open(dbName, version + 1);
                  req.onupgradeneeded = () => {
                    const upgradeDb = req.result;
                    for (const storeName in dbData) {
                      if (!upgradeDb.objectStoreNames.contains(storeName)) {
                        upgradeDb.createObjectStore(storeName);
                      }
                    }
                  };
                  req.onsuccess = () => resolve(req.result);
                  req.onerror = () => reject(req.error);
                });
              }
              
              for (const storeName in dbData) {
                const storeData = dbData[storeName];
                const tx = activeDb.transaction(storeName, 'readwrite');
                const store = tx.objectStore(storeName);
                store.clear();
                for (const key in storeData) {
                  let parsedKey = key;
                  if (!isNaN(key)) {
                    parsedKey = Number(key);
                  }
                  store.put(storeData[key], parsedKey);
                }
                await new Promise((resolve) => {
                  tx.oncomplete = resolve;
                });
              }
              activeDb.close();
            }
          })()
        ''');
      } catch (_) {}
    }
  }
}
