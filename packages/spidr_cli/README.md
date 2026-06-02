# spidr_cli

The command-line interface tool for running SPIDR scraping, crawling, and extraction jobs.

## Executable

The cli binary is run using:
```bash
dart run spidr_cli:spidr <command> [arguments]
```

## Available Commands

- `scrape`: Scrapes single web pages.
- `crawl`: Launches crawler configurations.
- `browser`: Launches CDP browser sessions.
- `session`: Manages saved session states.
- `extract`: Executes AI/schema extraction on text files.
- `fingerprint`: Evaluates element fingerprints.
