# spidr_crawler

The multi-threaded crawling orchestrator of the SPIDR framework. 

## Key Structures

- **`Spider`**: Subclass this to define start URLs, parsing rules, and scraping handlers.
- **`SpidrCrawler`**: The runtime coordinator execution engine.
- **`CrawlerQueue`**: Abstract queue interface supporting BFS (Breadth-First), DFS (Depth-First), and custom priority queue scheduling strategies.
- **`CrawlerScheduler`**: Frontier scheduler enforcing depth limits, request delay limits, and duplicate URL prevention.
