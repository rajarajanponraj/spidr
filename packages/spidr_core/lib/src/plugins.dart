/// Represents a modular extension that attaches functionality to the SPIDR ecosystem.
abstract class SpidrPlugin {
  /// The unique key name identifying this plugin.
  String get name;

  /// Invoked when the plugin is registered into the framework.
  void initialize(SpidrPluginRegistry registry);
}

/// Manages registration and lookups of SPIDR plugins at runtime.
class SpidrPluginRegistry {
  final Map<String, SpidrPlugin> _plugins = {};

  /// Registers a plugin into the registry.
  void register(SpidrPlugin plugin) {
    if (_plugins.containsKey(plugin.name)) {
      throw ArgumentError(
        'Plugin with name "${plugin.name}" is already registered.',
      );
    }
    _plugins[plugin.name] = plugin;
    plugin.initialize(this);
  }

  /// Retrieves a registered plugin by [name], casting it to [T].
  /// Returns null if the plugin is not found.
  T? get<T extends SpidrPlugin>(String name) {
    final plugin = _plugins[name];
    if (plugin == null) return null;
    return plugin as T;
  }

  /// Lists all registered plugin instances.
  Iterable<SpidrPlugin> get all => _plugins.values;
}
