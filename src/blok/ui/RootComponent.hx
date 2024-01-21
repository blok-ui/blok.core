package blok.ui;

import blok.signal.Runtime;
import blok.signal.Observer;
import blok.adaptor.*;
import blok.signal.Owner;

class RootComponent extends ComponentBase implements RealNodeHost {
  public static final componentType = new UniqueId();

  public static function node(props:{
    target:Dynamic, 
    child:()->Child,
    adaptor:Adaptor
  }) {
    return new VComponent(componentType, props, RootComponent.new);
  }

  final target:Dynamic;
  final child:()->Child;

  var component:Null<ComponentBase> = null;
  
  function new(node) {
    __node = node;
    (node.getProps():{
      target:Dynamic,
      child:()->Child,
      adaptor:Adaptor
    }).extract({ target: target, child: child, adaptor: adaptor });
    this.target = target;
    this.child = child;
    this.__adaptor = adaptor;
  }

  function render():Child {
    return Owner.with(this, ()-> Runtime.current().untrack(child));
  }

  function __initialize() {
    component = render().createComponent();
    component.mount(this, createSlot(0, null));
  }

  function __hydrate(cursor:Cursor) {
    component = render().createComponent();
    component.hydrate(cursor.currentChildren(), this, createSlot(0, null));
    cursor.next();
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

  public function visitChildren(visitor:(child:ComponentBase) -> Bool) {
    if (component != null) visitor(component);
  }
}