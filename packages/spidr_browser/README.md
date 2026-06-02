# spidr_browser

The browser automation layer of the SPIDR framework, powered by the Chrome DevTools Protocol (CDP).

## Core API Interfaces

- **`SpidrBrowser`**: Manages the underlying browser connection lifecycle (`launch`, `connect`, `close`).
- **`SpidrBrowserPage`**: Controller for pages/tabs executing actions like navigation, mouse clicks, keyboard entry, and script evaluation.
- **`SpidrBrowserTab`**: Representation of a separate tab within the browser.
