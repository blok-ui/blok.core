package blok.ui;

import blok.adaptor.RealNodeHost;
import blok.debug.Debug;

using blok.adaptor.RealNodeHostTools;

class Placeholder extends ComponentBase implements RealNodeHost {
  public static final componentType = new UniqueId();

  public static function node(?key):VNode {
    return new VComponent(componentType, {}, Placeholder.new, key);
  }

  var realNode:Null<Dynamic> = null;

  public function new(node:VNode) {
    __node = node;
  }

  function __initialize() {
    var adaptor = getAdaptor();
    realNode = adaptor.createPlaceholderNode();
    adaptor.insertNode(realNode, __slot, () -> this.findNearestRealNode());
  }

  function __hydrate(cursor:Cursor) {
    __initialize();
  }

  function __update() {}

  function __validate() {}

  function __dispose() {
    getAdaptor().removeNode(realNode, __slot);
  }
  
  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    getAdaptor().moveNode(getRealNode(), oldSlot, newSlot, () -> this.findNearestRealNode());
  }

  public function getRealNode():Dynamic {
    assert(realNode != null);
    return realNode;
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:ComponentBase) -> Bool) {}
}
