package blok;

@:nullSafety
abstract PluginCollection(Array<Plugin>) {
  public function new(plugins) {
    this = plugins;
  }

  inline public function add(plugin:Null<Plugin>) {
    if (plugin != null) this.push(plugin);
  }

  inline public function hasPlugins() {
    return this.length > 0;
  }

  inline public function remove(plugin:Null<Plugin>) {
    if (plugin != null) this.remove(plugin);
  }

  inline public function clear() {
    for (plugin in this) remove(plugin);
  }

  public function prepareVNodes(component:Component, vnode:VNodeResult):VNodeResult {
    var result = vnode;
    for (plugin in this) result = plugin.prepareVNodes(component, result);
    return result;
  }

  public function wasInitialized(component:Component):Void {
    for (plugin in this) plugin.wasInitialized(component);
  }

  public function wasRendered(component:Component):Void {
    for (plugin in this) plugin.wasRendered(component);
  }

  public function willBeDisposed(component:Component):Void {    
    for (plugin in this) plugin.willBeDisposed(component);
  }
}
