package blok.ui;

import blok.signal.Signal.ReadonlySignal;
import blok.debug.Debug;
import blok.adaptor.RealNodeHost;
import blok.diffing.Key;

using blok.adaptor.RealNodeHostTools;

abstract Text(VNode) to VNode from VNode {
  @:from public static function ofString(value:String):Text {
    return TextComponent.node(value);
  }

  @:from public static function ofSignal(signal:ReadonlySignal<String>):Text {
    return Scope.node({ child: _ -> Text.node(signal.get()) });
  }

  @:from public static function ofInt(number:Int) {
    return new Text(Std.string(number));
  }
  
  @:from public static function ofFloat(number:Float) {
    return new Text(Std.string(number));
  }

  public static function node(value:String):VNode {
    return new Text(value);
  }

  private function new(value, ?key) {
    this = TextComponent.node(value, key);
  }
}

class TextComponent extends Component implements RealNodeHost {
  public static final componentType = new UniqueId();

  public static function node(value:String, ?key:Key) {
    return new VComponent(componentType, { value: value }, TextComponent.new, key);
  }

  var realNode:Null<Dynamic> = null;

  function new(node) {
    __node = node;
  }

  function __initialize() {
    var adaptor = getAdaptor();
    var props:{ value:String } = __node.getProps();
    realNode = adaptor.createTextNode(props.value);
    adaptor.insertNode(realNode, __slot, () -> this.findNearestRealNode());
  }

  function __hydrate(cursor:Cursor) {
    realNode = cursor.current();
    assert(realNode != null, 'Hydration failed');
    cursor.next();
  }

  function __update() {
    var adaptor = getAdaptor();
    var props:{ value:String } = __node.getProps();
    adaptor.updateTextNode(realNode, props.value);
  }

  function __validate() {
    __update();
  }

  function __dispose() {
    getAdaptor().removeNode(realNode, __slot);
  }

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    getAdaptor().moveNode(realNode, oldSlot, newSlot, () -> this.findNearestRealNode());
  }

  public function getRealNode():Dynamic {
    assert(realNode != null);
    return realNode;
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:Component) -> Bool) {}
}