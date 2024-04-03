package blok.ui;

import blok.adaptor.*;
import blok.debug.Debug;

using blok.adaptor.PrimitiveHostTools;

class Placeholder extends View implements PrimitiveHost {
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
    adaptor.insertNode(realNode, __slot, () -> this.findNearestPrimitive());
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
    getAdaptor().moveNode(getPrimitive(), oldSlot, newSlot, () -> this.findNearestPrimitive());
  }

  public function getPrimitive():Dynamic {
    assert(realNode != null);
    return realNode;
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:View) -> Bool) {}
}
