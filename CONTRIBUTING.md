# Contributing to SPIDR

We welcome contributions to the SPIDR framework! As a high-performance open-source project intended for the pub.dev ecosystem, we maintain strict code guidelines to ensure security, testability, and cross-platform compatibility.

---

## Coding Standards

1. **Strong Typing**: Avoid `dynamic` types unless absolutely necessary (e.g. JSON serialization/deserialization bounds). Declare types on all public API boundaries.
2. **Platform Safety**: Avoid platform-exclusive imports (like `dart:html` or `dart:io`) directly in common directories. Use abstract interfaces and conditional imports/constructors to achieve platform isolation.
3. **Dart Lint Compliance**: Code must pass `dart analyze` with zero warnings, infos, or errors.
4. **Formatting**: Always format your code with `dart format .` before pushing.
5. **Testing**: Maintain a minimum test coverage of 90%. Any new feature or bug fix must include corresponding unit/integration tests.
6. **Documentation**: Write complete DartDoc comments on all public classes, functions, and parameters.

---

## Development Workflow

1. Fork the repository and create your branch from `develop`.
2. Install dependencies and verify workspace setup:
   ```bash
   dart pub get
   ```
3. Run the analysis and check formatting:
   ```bash
   dart analyze
   dart format --output=none --set-exit-if-changed .
   ```
4. Run tests:
   ```bash
   dart test
   ```
5. Commit your changes following standard semantic messages.
6. Open a Pull Request into the `develop` branch.
