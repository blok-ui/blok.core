package blok;

class Engine {
  public final plugins:PluginCollection;
  public final differ:Differ;

  public function new(plugins) {
    this.plugins = new PluginCollection(plugins);
    this.differ = new Differ(this);
  }
}
