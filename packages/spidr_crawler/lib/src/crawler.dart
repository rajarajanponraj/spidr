import 'dart:async';
import 'package:spidr_core/spidr_core.dart';

/// Subclass this to define spider-specific starting conditions and response parsing workflows.
abstract class Spider {
  /// Unique name identifying this spider.
  String get name;

  /// List of seed URLs where the crawling process begins.
  List<Uri> get startUrls;

  /// Parsed response callback handler. Extracts items or submits new requests back to the [crawler].
  Future<void> parse(SpidrResponse response, SpidrCrawler crawler);
}

/// Supported crawler search strategies.
enum CrawlStrategy {
  /// Breadth-First Search (scrapes shallow URLs before deep URLs).
  bfs,

  /// Depth-First Search (scrapes along a single path to limit depth first).
  dfs,
}

/// Manages crawling request frontiers, filtering duplicate visited URLs, and enforcing boundaries.
abstract class CrawlerScheduler {
  /// Evaluates if there are outstanding requests left in the queue.
  bool get isEmpty;

  /// Submits a request to the scheduler.
  void add(SpidrRequest request);

  /// Retrieves the next eligible request in accordance with the crawling strategy.
  SpidrRequest? next();

  /// Marks a specific URL as successfully scraped.
  void markVisited(Uri url);

  /// Evaluates if a URL has already been scraped or queued.
  bool isVisited(Uri url);

  /// Clear scheduler queues.
  void clear();
}

/// Default implementation of [CrawlerScheduler] supporting FIFO (BFS) and LIFO (DFS).
class DefaultCrawlerScheduler implements CrawlerScheduler {
  /// The crawl strategy (BFS or DFS).
  final CrawlStrategy strategy;
  final List<SpidrRequest> _queue = [];
  final Set<Uri> _visited = {};

  /// Creates a new [DefaultCrawlerScheduler] with [strategy].
  DefaultCrawlerScheduler({this.strategy = CrawlStrategy.bfs});

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  void add(SpidrRequest request) {
    _queue.add(request);
  }

  @override
  SpidrRequest? next() {
    if (_queue.isEmpty) return null;
    if (strategy == CrawlStrategy.bfs) {
      return _queue.removeAt(0);
    } else {
      return _queue.removeLast();
    }
  }

  @override
  void markVisited(Uri url) {
    _visited.add(url);
  }

  @override
  bool isVisited(Uri url) {
    return _visited.contains(url);
  }

  @override
  void clear() {
    _queue.clear();
    _visited.clear();
  }
}

/// Represents a single robots.txt directive rule.
class RobotsDirective {
  /// The type of directive ('allow', 'disallow', or 'crawl-delay').
  final String type;

  /// The path or value associated with the directive.
  final String value;

  /// Creates a new [RobotsDirective].
  const RobotsDirective(this.type, this.value);
}

/// Parser for robots.txt rules.
class RobotsTxt {
  /// User agent specific list of rules.
  final Map<String, List<RobotsDirective>> userAgentDirectives;

  /// Creates a new [RobotsTxt].
  const RobotsTxt(this.userAgentDirectives);

  /// Parses robots.txt file contents.
  static RobotsTxt parse(String content) {
    final directives = <String, List<RobotsDirective>>{};
    final lines = content.split(RegExp(r'\r?\n'));
    List<String> currentUserAgents = [];

    for (var line in lines) {
      final commentIdx = line.indexOf('#');
      if (commentIdx != -1) {
        line = line.substring(0, commentIdx);
      }
      line = line.trim();
      if (line.isEmpty) continue;

      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;

      final key = line.substring(0, colonIdx).trim().toLowerCase();
      final value = line.substring(colonIdx + 1).trim();

      if (key == 'user-agent') {
        final ua = value.toLowerCase();
        if (currentUserAgents.isNotEmpty && directives.containsKey(currentUserAgents.first)) {
          currentUserAgents = [];
        }
        currentUserAgents.add(ua);
        directives.putIfAbsent(ua, () => []);
      } else if (currentUserAgents.isNotEmpty) {
        if (key == 'disallow' || key == 'allow' || key == 'crawl-delay') {
          for (final ua in currentUserAgents) {
            directives[ua]!.add(RobotsDirective(key, value));
          }
        }
      }
    }

    return RobotsTxt(directives);
  }

  /// Evaluates if [path] is permitted for [userAgent].
  bool isAllowed(String userAgent, String path) {
    final normalizedUa = userAgent.toLowerCase();
    var rules = userAgentDirectives[normalizedUa];
    if (rules == null || rules.isEmpty) {
      rules = userAgentDirectives['*'] ?? const [];
    }

    RobotsDirective? bestMatch;
    for (final rule in rules) {
      if (rule.type == 'disallow' || rule.type == 'allow') {
        final rulePath = rule.value;
        if (path.startsWith(rulePath)) {
          if (bestMatch == null || rulePath.length > bestMatch.value.length) {
            bestMatch = rule;
          }
        }
      }
    }

    if (bestMatch != null) {
      return bestMatch.type == 'allow';
    }

    return true;
  }

  /// Returns the crawl delay value in seconds, if specified.
  double? getCrawlDelay(String userAgent) {
    final normalizedUa = userAgent.toLowerCase();
    var rules = userAgentDirectives[normalizedUa];
    if (rules == null || rules.isEmpty) {
      rules = userAgentDirectives['*'] ?? const [];
    }
    for (final rule in rules) {
      if (rule.type == 'crawl-delay') {
        return double.tryParse(rule.value);
      }
    }
    return null;
  }
}

/// Helper that downloads, parses, and caches robots.txt configuration dynamically.
class RobotsManager {
  /// Client to perform network calls.
  final SpidrClient client;

  /// User agent to match in robots directives.
  final String userAgent;

  final Map<String, RobotsTxt> _cache = {};

  /// Creates a new [RobotsManager].
  RobotsManager(this.client, {this.userAgent = 'spidr'});

  /// Resolves if [url] is allowed under host's robots.txt rules.
  Future<bool> isAllowed(Uri url) async {
    final robotsTxt = await _fetchRobots(url);
    final path = url.path.isEmpty ? '/' : url.path;
    return robotsTxt.isAllowed(userAgent, path);
  }

  /// Resolves if there's a crawl delay declared for the current user agent.
  Future<double?> getCrawlDelay(Uri url) async {
    final robotsTxt = await _fetchRobots(url);
    return robotsTxt.getCrawlDelay(userAgent);
  }

  Future<RobotsTxt> _fetchRobots(Uri url) async {
    final hostKey = '${url.scheme}://${url.host}:${url.port}';
    if (_cache.containsKey(hostKey)) {
      return _cache[hostKey]!;
    }

    final robotsUrl = Uri(
      scheme: url.scheme,
      userInfo: url.userInfo,
      host: url.host,
      port: url.port,
      path: '/robots.txt',
    );

    try {
      final response = await client.send(SpidrRequest(url: robotsUrl));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final robots = RobotsTxt.parse(response.bodyString);
        _cache[hostKey] = robots;
        return robots;
      }
    } catch (_) {}

    const robots = RobotsTxt({});
    _cache[hostKey] = robots;
    return robots;
  }
}

/// Orchestrates the crawling and execution loop.
class SpidrCrawler {
  /// The crawler's active scraping logic definition.
  final Spider spider;

  /// The HTTP/Browser client interface used to retrieve documents.
  final SpidrClient client;

  /// The scheduling queue.
  final CrawlerScheduler scheduler;

  /// Maximum crawling depth boundary.
  final int maxDepth;

  /// Time to pause between requests.
  final Duration delay;

  /// Whether to obey robots.txt directives.
  final bool respectRobots;

  /// User agent identifying string for robots.txt parsing.
  final String userAgent;

  /// The maximum number of concurrent request executions.
  final int concurrency;

  final Map<String, DateTime> _lastRequestTimes = {};
  late final RobotsManager _robotsManager;

  /// Creates a new [SpidrCrawler].
  SpidrCrawler({
    required this.spider,
    required this.client,
    required this.scheduler,
    this.maxDepth = 3,
    this.delay = Duration.zero,
    this.respectRobots = true,
    this.userAgent = 'spidr',
    this.concurrency = 1,
  }) {
    _robotsManager = RobotsManager(client, userAgent: userAgent);
  }

  /// Commences execution. Loops until the scheduler is exhausted.
  Future<void> run() async {
    for (final url in spider.startUrls) {
      scheduler.add(SpidrRequest(
        url: url,
        extra: const {'depth': 0},
      ));
    }

    final activeFutures = <Future<void>>{};
    final completer = Completer<void>();

    void nextTask() {
      if (scheduler.isEmpty && activeFutures.isEmpty) {
        if (!completer.isCompleted) completer.complete();
        return;
      }

      while (activeFutures.length < concurrency && !scheduler.isEmpty) {
        final request = scheduler.next();
        if (request == null) break;

        final currentDepth = request.extra['depth'] as int? ?? 0;
        if (currentDepth > maxDepth) continue;

        final future = _processRequest(request);
        activeFutures.add(future);
        future.whenComplete(() {
          activeFutures.remove(future);
          nextTask();
        });
      }

      if (scheduler.isEmpty && activeFutures.isEmpty) {
        if (!completer.isCompleted) completer.complete();
      }
    }

    nextTask();
    await completer.future;
  }

  Future<void> _processRequest(SpidrRequest request) async {
    if (respectRobots) {
      final allowed = await _robotsManager.isAllowed(request.url);
      if (!allowed) return;
    }

    final hostKey = '${request.url.scheme}://${request.url.host}:${request.url.port}';
    final now = DateTime.now();

    var targetDelay = delay;
    if (respectRobots) {
      final robotsDelay = await _robotsManager.getCrawlDelay(request.url);
      if (robotsDelay != null) {
        final robotsDuration = Duration(milliseconds: (robotsDelay * 1000).toInt());
        if (robotsDuration > targetDelay) {
          targetDelay = robotsDuration;
        }
      }
    }

    final lastRequest = _lastRequestTimes[hostKey];
    var waitTime = Duration.zero;
    if (lastRequest != null && targetDelay > Duration.zero) {
      final plannedTime = lastRequest.add(targetDelay);
      if (plannedTime.isAfter(now)) {
        waitTime = plannedTime.difference(now);
      }
    }

    _lastRequestTimes[hostKey] = now.add(waitTime).add(targetDelay);

    if (waitTime > Duration.zero) {
      await Future<void>.delayed(waitTime);
    }

    if (scheduler.isVisited(request.url)) return;
    scheduler.markVisited(request.url);

    await runZoned(() async {
      try {
        final response = await client.send(request);
        await spider.parse(response, this);
      } catch (_) {
        // Suppress or delegate to dynamic middleware logger in later phases
      }
    }, zoneValues: {#currentRequest: request});
  }

  /// Manually queue additional requests discovered during scraping.
  void submit(SpidrRequest request) {
    var updatedRequest = request;
    if (!request.extra.containsKey('depth')) {
      final currentRequest = Zone.current[#currentRequest] as SpidrRequest?;
      final currentDepth = currentRequest?.extra['depth'] as int? ?? 0;
      updatedRequest = request.copyWith(
        extra: {
          ...request.extra,
          'depth': currentDepth + 1,
        },
      );
    }
    scheduler.add(updatedRequest);
  }
}
