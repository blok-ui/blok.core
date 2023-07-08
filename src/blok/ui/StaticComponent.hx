package blok.ui;

import blok.signal.Graph;
import blok.diffing.Differ;
import blok.debug.Debug;

abstract class StaticComponent extends Component {
  var __child:Null<Component> = null;

  abstract function setup():Void;
  abstract function render():VNode;
  abstract function __updateProps():Bool;

  function __render() {
    return untrackValue(render) ?? Placeholder.node();
  }

  function __initialize() {
    setup();
    __child = __render().createComponent();
    __child.mount(this, __slot);
  }

  function __hydrate(cursor:Cursor) {
    setup();
    __child = __render().createComponent();
    __child.hydrate(cursor, this, __slot);
  }

  function __update() {
    if (__updateProps()) {
      __child = updateChild(this, __child, __render(), __slot);
    }
  }

  function __validate() {
    warn('Static components should not be invalidated! '
      + ' They should only be updated when a VNode tree changes. '
      + 'Consider changing this component to an ObserverComponent '
      + 'if this is the behavior you want.'
    );
  }

  #if debug
  override function invalidate() {
    warn('Static components should not be invalidated! '
      + ' They should only be updated when a VNode tree changes. '
      + 'Consider changing this component to an ObserverComponent '
      + 'if this is the behavior you want.'
    );
    super.invalidate();
  }
  #end

  function __dispose() {}

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    __child?.updateSlot(newSlot);
  }

  public function getRealNode():Dynamic {
    var node:Null<Dynamic> = null;

    visitChildren(component -> {
      assert(node == null, 'Component has more than one nodes');
      node = component.getRealNode();
      true;
    });

    assert(node != null, 'Component does not have an node');

    return node;
  }

  public function visitChildren(visitor:(child:Component) -> Bool) {
    if (__child != null) visitor(__child);
  }
}
