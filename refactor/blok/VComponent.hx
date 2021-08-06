package blok;

@:allow(blok.Component)
class VComponent<Props:{}> implements VNode {
  public final type:WidgetType;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>> = null;
  public final factory:(props:Props)->Component;

  public function new(type, props:Props, factory, key) {
    this.type = type;
    this.props = props;
    this.factory = factory;
    this.key = key;
  }

  public function createWidget(?parent, platform, registerEffect):Widget {
    var component = factory(props);
    component.initializeWidget(parent, platform, key);
    component.performUpdate(registerEffect);
    return component;
  }

  public function updateWidget(widget:Widget, registerEffect) {
    var component:Component = cast widget;
    component.updateComponentProperties(props);
    if (component.shouldComponentRender()) {
      component.performUpdate(registerEffect);
    }
    return component;
  }
}
