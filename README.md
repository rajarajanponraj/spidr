# SPIDR

[![CI Status](https://github.com/spidr-scraping/spidr/actions/workflows/ci.yml/badge.svg)](https://github.com/spidr-scraping/spidr/actions/workflows/ci.yml)
[![Pub Version](https://img.shields.io/pub/v/spidr.svg)](https://pub.dev/packages/spidr)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A next-generation adaptive web scraping, browser automation, crawling, extraction, and data acquisition framework built specifically for Dart and Flutter. 

SPIDR is built from the ground up as a pure-Dart framework. It provides a robust, cross-platform library that enables high-scale scraping on Server, CLI, Desktop (Windows, macOS, Linux), Web, and Mobile (Android, iOS).

---

## Key Features

- **Pure Dart & Flutter Developer Experience**: No wrappers around Python or Node.js scripts. Clean, type-safe API.
- **Cross-Platform Out of the Box**: Unified APIs compiling on Dart VM, Flutter Web, Desktop, Mobile, and Server.
- **Browser Automation via CDP**: Built-in Chrome DevTools Protocol implementation without external heavy native bindings.
- **Self-Healing Adaptive Selector Engine**: Automatic recovery and relocation of elements when target websites change their layout/markup.
- **Modular Plugin Architecture**: Thin core package with pluggable subsystems for Storage, Stealth mechanisms, Proxy Management, Crawler Scheduling, and AI-powered extraction.
- **Enterprise-Scale Features**: Structured concurrency with Dart Isolates, fault-tolerance, resume/pause queues, and rate limiting.

---

## Repository Structure

This project is organized as a multi-package Dart monorepo under `packages/`:

| Package | Path | Purpose |
|---------|------|---------|
| **`spidr`** | [packages/spidr](file:///packages/spidr) | Umbrella package containing the main facade API. |
| **`spidr_core`** | [packages/spidr_core](file:///packages/spidr_core) | Core models, interfaces, capability systems, and common types. |
| **`spidr_browser`** | [packages/spidr_browser](file:///packages/spidr_browser) | CDP client, tab manager, page actions, and browser launch helpers. |
| **`spidr_crawler`** | [packages/spidr_crawler](file:///packages/spidr_crawler) | Multi-threaded Spider engine, BFS/DFS schedulers, duplicate check. |
| **`spidr_stealth`** | [packages/spidr_stealth](file:///packages/spidr_stealth) | Canvas/WebGL masking, User-Agent rotation, humanlike delay injections. |
| **`spidr_storage`** | [packages/spidr_storage](file:///packages/spidr_storage) | Persistence layer supporting Isar, SQLite, and Web IndexedDB. |
| **`spidr_proxy`** | [packages/spidr_proxy](file:///packages/spidr_proxy) | Rotating proxies, SOCKS5/HTTP protocols, validation pool. |
| **`spidr_ai`** | [packages/spidr_ai](file:///packages/spidr_ai) | LLM schema parser, DOM-to-JSON inference models. |
| **`spidr_cli`** | [packages/spidr_cli](file:///packages/spidr_cli) | CLI binary (`spidr`) for running jobs, scraping, and managing sessions. |

---

## Quick Start

Add the umbrella package `spidr` to your `pubspec.yaml`:

```yaml
dependencies:
  spidr: ^0.1.0
```

Initialize SPIDR and perform simple requests:

```dart
import 'package:spidr/spidr.dart';

void main() async {
  // Execute a simple HTTP scrape
  final page = await Spidr.get("https://example.com");
  
  // Extract text using CSS selectors
  final title = page.css("h1").text;
  print("Page Title: $title");

  // Use the self-healing adaptive selector engine
  final products = page.adaptive(".product-card");
  
  // Convert elements into typed objects
  final data = page.extract<Product>();
}
```

---

## Documentation

- [System Architecture](file:///ARCHITECTURE.md)
- [Project Roadmap](file:///ROADMAP.md)
- [Contributing Guide](file:///CONTRIBUTING.md)
- [Code of Conduct](file:///CODE_OF_CONDUCT.md)
