package blok.ui;

import blok.adaptor.*;
import blok.diffing.Differ;

class Fragment extends ComponentBase {
  public static final componentType = new UniqueId();

  public static function node(...children:Child):VNode {
    return new VComponent(componentType, { children: children }, Fragment.new);
  }

  var children:Array<ComponentBase> = [];
  var marker:Null<ComponentBase> = null;

  private function new(node) {
    __node = node;
  }

  function render() {
    var props:{ children:Array<Child> } = __node.getProps();
    return props.children.filter(c -> c != null);
  }

  override function createSlot(localIndex:Int, previous:Null<ComponentBase>):Slot {
    return new FragmentSlot(__slot?.index ?? 0, localIndex + 1, previous);
  }

  function __initialize() {
    marker = Placeholder.node().createComponent();
    marker.mount(this, createSlot(-1, __slot?.previous));
    
    var previous = marker;
    var nodes = render();
    var newChildren:Array<ComponentBase> = [];

    for (i => node in nodes) {
      var child = node.createComponent();
      child.mount(this, createSlot(i, previous));
      newChildren.push(child);
      previous = child;
    }
  
    this.children = newChildren;
  }

  function __hydrate(cursor:Cursor) {
    marker = Placeholder.node().createComponent();
    marker.mount(this, createSlot(-1, __slot?.previous));
    
    var previous = marker;
    var nodes = render();
    var newChildren:Array<ComponentBase> = [];

    for (i => node in nodes) {
      var child = node.createComponent();
      child.hydrate(cursor, this, createSlot(i, previous));
      newChildren.push(child);
      previous = child;
    }
  
    this.children = newChildren;
  }

  function __update() {
    children = diffChildren(this, children, render());
  }

  function __validate() {
    __update();
  }

  function __dispose() {
    marker?.dispose();
    marker = null;
  }

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    if (marker != null) {
      marker.updateSlot(createSlot(-1, newSlot?.previous));
      var previous = marker;
      for (i => child in children) {
        child.updateSlot(createSlot(i, previous));
        previous = child;
      }
    }
  }

  public function getRealNode():Dynamic {
    if (children.length == 0) {
      return marker?.getRealNode();
    }
    return children[children.length - 1].getRealNode();
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:ComponentBase) -> Bool) {
    for (child in children) if (!visitor(child)) return;
  }
}

class FragmentSlot extends Slot {
  public final localIndex:Int;

  public function new(index, localIndex, previous) {
    super(index, previous);
    this.localIndex = localIndex;
  }

  override function changed(other:Slot):Bool {
    // Note: this is just for now -- need to figure out
    // a better way to make sure we don't move nodes around 
    // pointlessly, but if we don't do this Fragments won't
    // work with Suspense.
    return other != this;

    // if (super.changed(other)) {
    //   return true;
    // }
    // if (other is FragmentSlot) {
    //   var otherFragment:FragmentSlot = cast other;
    //   return localIndex != otherFragment.localIndex;
    // }
    // return false;
  }
}
