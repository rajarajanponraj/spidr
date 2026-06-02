# spidr_core

The foundational component of the SPIDR scraping framework. This package defines the core types, interfaces, platform capabilities, models, and exception models shared across all SPIDR plugin packages.

## Structure

- **`SpidrRequest` & `SpidrResponse`**: The unified network data exchange models.
- **`SpidrPage` & `SpidrElement`**: Parsed DOM wrappers exposing selector APIs.
- **`SpidrClient`**: The standard interface for request executors.
- **`SpidrCapabilities`**: The runtime platform capability inspection registry.
- **`SpidrPlugin` & `SpidrPluginRegistry`**: Extension endpoints supporting dynamic loading of storage, AI, stealth, crawler, and proxy layers.
