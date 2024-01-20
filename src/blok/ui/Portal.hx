package blok.ui;

import blok.adaptor.Cursor;
import blok.debug.Debug;

typedef PortalProps = {
  public final target:Dynamic;
  public final child:()->Child;
} 

class Portal extends ComponentBase {
  public static final componentType = new UniqueId();

  @:fromMarkup
  @:noUsing
  @:noCompletion
  public static inline function fromMarkup(props:{
    public final target:Dynamic;
    @:children public final child:()->Child;
  }) {
    return wrap(props.target, props.child);
  };

  public inline static function wrap(target:Dynamic, child:()->Child, ?key) {
    return node({
      target: target,
      child: child
    }, key);
  }

  public static function node(props:PortalProps, ?key) {
    return new VComponent(componentType, props, Portal.new, key);
  }

  var target:Null<Dynamic> = null;
  var child:Null<()->Child> = null;
  var marker:Null<ComponentBase> = null;
  var root:Null<ComponentBase> = null;

  function new(node) {
    __node = node;
    updateProps();
  }

  function setupPortalRoot() {
    root = RootComponent.node({
      target: target,
      child: child,
      adaptor: getAdaptor()
    }).createComponent();
  }

  function updateProps() {
    var props:PortalProps = __node.getProps();
    this.target = props.target;
    this.child = props.child;
  }

  function __initialize() {
    marker = Placeholder.node().createComponent();
    marker.mount(this, __slot);
    setupPortalRoot();
    root.mount(this, null);
  }

  function __hydrate(cursor:Cursor) {
    marker = Placeholder.node().createComponent();
    marker.mount(this, __slot);
    setupPortalRoot();
    root.hydrate(getAdaptor().createCursor(target), this, null);
  }

  function __update() {
    updateProps();
    root.update(RootComponent.node({
      target: target,
      child: child,
      adaptor: getAdaptor()
    }));
  }

  function __validate() {
    root.validate();
  }

  function __dispose() {
    root?.dispose();
    root = null;
    marker?.dispose();
    marker = null;
  }

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    marker?.updateSlot(newSlot);
  }

  public function getRealNode():Dynamic {
    assert(marker != null);
    return marker.getRealNode();
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:ComponentBase) -> Bool) {
    root?.visitChildren(visitor);
  }
}
