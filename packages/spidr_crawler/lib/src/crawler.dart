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

/// Orchestrates the scraping and execution loop.
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

  /// Creates a new [SpidrCrawler].
  SpidrCrawler({
    required this.spider,
    required this.client,
    required this.scheduler,
    this.maxDepth = 3,
    this.delay = Duration.zero,
  });

  /// Commences execution. Loops until the scheduler is exhausted.
  Future<void> run() async {
    for (final url in spider.startUrls) {
      scheduler.add(SpidrRequest(url: url));
    }

    while (!scheduler.isEmpty) {
      final request = scheduler.next();
      if (request == null) break;

      if (scheduler.isVisited(request.url)) continue;
      scheduler.markVisited(request.url);

      try {
        final response = await client.send(request);
        await spider.parse(response, this);
      } catch (_) {
        // Suppress or delegate to dynamic middleware logger in later phases
      }

      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }
  }

  /// Manually queue additional requests discovered during scraping.
  void submit(SpidrRequest request) {
    scheduler.add(request);
  }
}
