# SPIDR Roadmap

This document outlines the development phases for the SPIDR scraping, browser automation, and data extraction ecosystem.

---

## 🗺️ Execution Phases

### Phase 1: Foundation (Current)
- [x] Configure workspace monorepo & project scaffold
- [x] Establish strict analyzer and lint settings
- [x] Formulate CI configuration (GitHub Actions)
- [x] Complete architecture and contributor documentation

### Phase 2: Networking Layer
- [ ] Implement `SpidrClient` and `HttpClient` requests engine
- [ ] Setup response structures and headers processing
- [ ] Design middlewares (request/response pipeline)
- [ ] Build automatic retry policies, backing off, rate limiting
- [ ] Add cookie jar managers and proxy connection configurations

### Phase 3: HTML Parsing Layer
- [ ] Integrate selector engines (CSS & XPath parser bindings)
- [ ] Build DOM wrapper structures (`Page`, `Element`)
- [ ] Implement attribute extraction, text scrubbing, and HTML tree walkers

### Phase 4: Browser Automation Layer
- [ ] Build native WebSocket connection interface to Chromium over Chrome DevTools Protocol (CDP)
- [ ] Launch/connect local or remote Chrome binaries
- [ ] Develop browser/tab/page controllers
- [ ] Implement Page methods: `goto`, `click`, `type`, `waitFor`, `evaluate`, and `screenshot`

### Phase 5: Rendering Engine
- [ ] Support dynamic SPA content rendering (React, Angular, Vue, Next.js)
- [ ] Implement fallback `page.render()` executing custom scripts and awaiting DOM state transitions

### Phase 6: Fingerprint Engine
- [x] Implement `ElementFingerprint` captures: tags, classes, attributes, XPath/CSS positions, sibling structures, depth, parent hashes
- [x] Design fingerprint serialization and persistence contracts

### Phase 7: Adaptive Selector Engine
- [ ] Formulate self-healing algorithms that compare current DOM elements with historical fingerprints when a target selector breaks
- [ ] Build similarity metrics matching and confidence-score calculations
- [ ] Implement `page.adaptive()` facade

### Phase 8: Session Layer
- [ ] Support complete state save and load: cookies, headers, local storage, indexDB state, session contexts
- [ ] Expose `save()` and `restore()` abstractions

### Phase 9: Crawler Framework
- [ ] Define the crawler skeleton: `Spider`, `Request`, `Response`, `Crawler`, `Scheduler`
- [ ] Provide BFS (Breadth-First) and DFS (Depth-First) crawling strategies
- [ ] Handle robots.txt parsing and request limits

### Phase 10: Concurrent Execution
- [ ] Isolate worker pools for multi-core scraping operations
- [ ] Build concurrent stream extraction pipelines

### Phase 11: Storage Layer
- [ ] Implement storage adapters supporting mobile (Isar), desktop/server (Isar, SQLite), and web (IndexedDB)
- [ ] Automate capability checks and runtime environment routing

### Phase 12: Stealth Layer
- [ ] Build fingerprint spoofers: User-Agent rotations, header sequences, viewport randomizations
- [ ] Canvas, WebGL, WebAudio, and system font footprint masking mechanisms

### Phase 13: Proxy Layer
- [ ] Build validation pool engine (`ProxyPool`)
- [ ] HTTP, HTTPS, SOCKS5 protocols
- [ ] Proxy rotation strategies: Round-robin, Weighted, Random, Sticky sessions

### Phase 14: AI Extraction
- [ ] Build typed parsing engine: `page.extract<T>()`
- [ ] Leverage LLM semantic structural extraction with customizable backends

### Phase 15: CLI Tool
- [ ] Write `spidr` executable interface
- [ ] CLI tools: `scrape`, `crawl`, `browser`, `session`, `extract`, `fingerprint`
