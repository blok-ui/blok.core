package blok;

@:allow(blok.Component)
class VComponent<Props:{}> implements VNode {
  public final type:VNodeType;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>> = null;
  public final factory:(props:Props)->Component;

  public function new(type, props:Props, factory, key) {
    this.type = type;
    this.key = key;
    this.props = props;
    this.factory = factory;
  }

  public function createComponent(engine:Engine, ?parent:Component):Component {
    var component = factory(props);
    component.initializeComponent(parent, engine, key);
    component.renderComponent();
    return component;
  }

  public function updateComponent(engine:Engine, component:Component) {
    component.updateComponentProperties(props);
    if (component.shouldComponentRender()) {
      component.renderComponent();
    }
    return component;
  }
}
