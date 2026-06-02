# spidr_proxy

The proxy configuration and validation layer of the SPIDR framework.

## Abstractions

- **`ProxyInfo`**: Represents details of an HTTP, HTTPS, or SOCKS5 proxy server.
- **`ProxyPool`**: Collects available proxies and rotates requests in accordance with a selection strategy.
- **`ProxyRotationStrategy`**: Defines rotation behaviors (e.g. random, round-robin, weighted, sticky).
