package blok.ui;

import blok.adaptor.Adaptor;
import blok.adaptor.RealNodeHost;

class RootComponent extends Component implements RealNodeHost {
  public static final componentType = new UniqueId();

  public static function node(props:{
    target:Dynamic, 
    child:Child,
    adaptor:Adaptor
  }) {
    return new VComponent(componentType, props, RootComponent.new);
  }

  final target:Dynamic;
  final child:Child;

  var component:Null<Component> = null;
  
  function new(node) {
    __node = node;
    (node.getProps():{
      target:Dynamic,
      child:Child,
      adaptor:Adaptor
    }).extract({ target: target, child: child, adaptor: adaptor });
    this.target = target;
    this.child = child;
    this.__adaptor = adaptor;
  }

  function __initialize() {
    component = child.createComponent();
    component.mount(this, createSlot(0, null));
  }

  function __hydrate(cursor:Cursor) {
    component = child.createComponent();
    component.hydrate(cursor, this, createSlot(0, null));
  }

  function __update() {}

  function __validate() {}

  function __dispose() {}

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    component.updateSlot(newSlot);
  }

  public function getRealNode():Dynamic {
    return target;
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return false;
  }

  public function visitChildren(visitor:(child:Component) -> Bool) {
    if (component != null) visitor(component);
  }
}