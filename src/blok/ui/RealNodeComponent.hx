package blok.ui;

import blok.adaptor.*;
import blok.core.Disposable;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.signal.Graph;
import blok.signal.Observer;
import blok.signal.Signal;

using blok.adaptor.RealNodeHostTools;

class RealNodeComponent extends ComponentBase implements RealNodeHost {
  final tag:String;
  final type:UniqueId;
  final updaters:Map<String, NativePropertyUpdater<Any>> = [];

  var hydrating:Bool = false;
  var realNode:Null<Dynamic> = null;
  var children:Array<ComponentBase> = [];

  public function new(node:VRealNode) {
    tag = node.tag;
    type = node.type;
    __node = node;
  }

  function render() {
    var vn:VRealNode = cast __node;
    return vn.children ?? [];
  }

  function observeAttributes() {
    function applyAttribute(name:String, oldValue:Any, value:Any) {
      getAdaptor().updateNodeAttribute(getRealNode(), name, oldValue, value, hydrating);
    }

    var props = __node.getProps();
    var fields = Reflect.fields(props);

    for (name in updaters.keys()) {
      if (!fields.contains(name)) {
        updaters.get(name)?.dispose();
        updaters.remove(name);
      }
    }

    withOwner(this, () -> for (name in fields) {
      var signal:ReadonlySignal<Any> = Reflect.field(props, name);
      var updater = updaters.get(name);
      if (updater == null) {
        updater = new NativePropertyUpdater(name, signal, applyAttribute);
        updaters.set(name, updater);
      } else {
        updater.update(signal);
      }
    });
  }

  function __initialize() {
    realNode = createRealNode();
    observeAttributes();
    
    var nodes = render();
    var previous:ComponentBase = null;
  
    children = [ for (i => node in nodes) {
      var child = node.createComponent();
      child.mount(this, createSlot(i, previous));
      previous = child;
      child;
    } ];
    getAdaptor().insertNode(realNode, __slot, () -> this.findNearestRealNode());
  }

  function __hydrate(cursor:Cursor) {
    hydrating = true;
    realNode = cursor.current();
    observeAttributes();

    var nodes = render();
    var localCursor = getAdaptor().createCursor(realNode);
    var previous:ComponentBase = null;
  
    children = [ for (i => node in nodes) {
      var child = node.createComponent();
      child.hydrate(localCursor, this, createSlot(i, previous));
      previous = child;
      child;
    } ];
    
    assert(localCursor.current() == null);
    
    hydrating = false;

    cursor.next();
  }

  function __update() {
    observeAttributes();
    children = diffChildren(this, children, render());
  }

  function __validate() {
    children = diffChildren(this, children, render());
  }

  function __dispose() {
    for (_ => updater in updaters) {
      updater.dispose();
    }
    updaters.clear();
    getAdaptor().removeNode(getRealNode(), __slot);
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

  public function visitChildren(visitor:(child:ComponentBase) -> Bool) {
    for (child in children) if (!visitor(child)) return;
  }
}

class NativePropertyUpdater<T> implements Disposable {
  final changeSignal:Signal<ReadonlySignal<T>>;
  final observer:Observer;

  var oldValue:Null<T> = null;
  
  public function new(
    name:String,
    propSignal:ReadonlySignal<T>,
    setRealAttr
  ) {
    this.changeSignal = new Signal(propSignal);
    this.observer = new Observer(() -> {
      var value = changeSignal.get().get();
      if (value == oldValue) return;
      setRealAttr(name, oldValue, value);
      oldValue = value;
    });
  }

  public function update(newSignal:ReadonlySignal<T>) {
    changeSignal.set(newSignal);
  }

  public function dispose() {
    changeSignal.dispose();
    observer.dispose();
  }
}
