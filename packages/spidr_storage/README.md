# spidr_storage

The modular storage and persistence abstraction layer of the SPIDR framework.

## Abstractions

- **`StorageAdapter`**: Interface for persisting HTTP request cookies, crawler queue frontiers, session contexts, and scraped element fingerprints.
- **`MemoryStorageAdapter`**: A lightweight, in-memory reference implementation suitable for testing and ephemeral crawls.
