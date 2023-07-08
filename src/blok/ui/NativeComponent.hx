package blok.ui;

import blok.signal.Graph.withOwner;
import blok.diffing.Differ.diffChildren;
import blok.adaptor.RealNodeHost;
import blok.debug.Debug;
import blok.signal.Observer;
import blok.signal.Signal;

using blok.adaptor.RealNodeHostTools;

class NativeComponent extends Component implements RealNodeHost {
  final tag:String;
  final type:UniqueId;
  final attributes:Map<String, ReadonlySignal<Any>> = [];

  var realNode:Null<Dynamic> = null;
  var children:Array<Component> = [];

  public function new(node:VNative) {
    tag = node.tag;
    type = node.type;
    __node = node;
  }

  function render() {
    var vn:VNative = cast __node;
    return vn.children ?? [];
  }

  // @todo: Figure out a better way to handle attributes.
  function setupAttributes(hydrating:Bool = false) {
    inline function applyAttribute(name:String, signal:ReadonlySignal<Any>) {
      var value = signal.get();
      getAdaptor().updateNodeAttribute(getRealNode(), name, value, hydrating);
    }

    withOwner(this, () -> {
      var props:{} = __node.getProps();
      for (field in Reflect.fields(props)) {
        // @todo: This will break super easily.
        if (!attributes.exists(field)) {
          var signal = Reflect.field(props, field);
          attributes.set(field, signal);
          if (signal.isInactive()) {
            applyAttribute(field, signal);
          } else {
            Observer.track(() -> applyAttribute(field, signal));
          }
        }
      }
    });
  }

  function __initialize() {
    realNode = createRealNode();
    
    setupAttributes();
    
    var nodes = render();
    var previous:Component = null;
  
    children = [ for (i => node in nodes) {
      var child = node.createComponent();
      child.mount(this, createSlot(i, previous));
      previous = child;
      child;
    } ];

    getAdaptor().insertNode(realNode, __slot, () -> this.findNearestRealNode());
  }

  function __hydrate(cursor:Cursor) {
    realNode = cursor.current();

    setupAttributes(true);

    var nodes = render();
    var localCursor = getAdaptor().createCursor(realNode);
    var previous:Component = null;
  
    children = [ for (i => node in nodes) {
      var child = node.createComponent();
      child.hydrate(localCursor, this, createSlot(i, previous));
      previous = child;
      child;
    } ];
    
    assert(localCursor.current() == null);
    cursor.next();
  }

  function __update() {
    setupAttributes();
    children = diffChildren(this, children, render());
  }

  function __validate() {
    children = diffChildren(this, children, render());
  }

  function __dispose() {
    attributes.clear();
  }

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    getAdaptor().moveNode(getRealNode(), oldSlot, newSlot, () -> this.findNearestRealNode());
  }

  function createRealNode() {
    return getAdaptor().createNode(tag, {});
  }

  public function getRealNode():Dynamic {
    assert(realNode != null);
    return realNode;
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return type == node.type;
  }

  public function visitChildren(visitor:(child:Component) -> Bool) {
    for (child in children) if (!visitor(child)) return;
  }
}
