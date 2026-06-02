import 'package:spidr_core/spidr_core.dart';

/// Configuration profiles for the evasion and anti-fingerprinting plugin.
class StealthConfig implements SpidrPlugin {
  /// Rotates the request/navigation User-Agent header dynamically.
  final bool enableUserAgentRotation;

  /// Shuffles request header lists.
  final bool enableHeaderRotation;

  /// Changes the viewport resolution profile.
  final bool enableViewportRandomization;

  /// Inserts soft noise to isolate HTML5 Canvas fingerprints.
  final bool enableCanvasMasking;

  /// Injects custom graphics driver parameters.
  final bool enableWebGLMasking;

  /// Masks audio API profiles.
  final bool enableAudioMasking;

  /// Randomizes available font layouts.
  final bool enableFontMasking;

  /// Navigator language code (e.g. 'en-US', 'de-DE').
  final String language;

  /// Client timezone identifier (e.g. 'Europe/Berlin').
  final String timezone;

  /// Creates a custom [StealthConfig] profile.
  const StealthConfig({
    this.enableUserAgentRotation = true,
    this.enableHeaderRotation = true,
    this.enableViewportRandomization = true,
    this.enableCanvasMasking = true,
    this.enableWebGLMasking = true,
    this.enableAudioMasking = true,
    this.enableFontMasking = true,
    this.language = 'en-US',
    this.timezone = 'America/New_York',
  });

  @override
  String get name => 'spidr_stealth';

  @override
  void initialize(SpidrPluginRegistry registry) {
    // Initial plugin attachment setup
  }
}

/// Generates organic User-Agent profiles for requests and browser engines.
class UserAgentGenerator {
  static const List<String> _desktopUserAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  ];

  /// Shuffles and returns a random desktop User-Agent string.
  static String randomDesktop() {
    return (List<String>.from(_desktopUserAgents)..shuffle()).first;
  }
}
