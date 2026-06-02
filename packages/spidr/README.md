# spidr

The umbrella package of the SPIDR framework, re-exporting all core modules and providing a simplified facade entry point.

## Core Facade API

The `Spidr` class serves as the root facade:

```dart
import 'package:spidr/spidr.dart';

void main() async {
  // Simple GET request
  final page = await Spidr.get("https://example.com");
  print(page.css("h1")?.text);
}
```
