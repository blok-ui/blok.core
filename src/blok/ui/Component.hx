package blok.ui;

import blok.adaptor.Cursor;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.signal.Computation;
import blok.signal.Graph;

using blok.boundary.BoundaryTools;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends ComponentBase {
  var __child:Null<ComponentBase> = null;
  var __rendered:Null<Computation<Null<VNode>>> = null;

  abstract function setup():Void;
  abstract function render():Child;
  abstract function __updateProps():Void;

  function __render():VNode {
    if (__rendered != null) {
      removeDisposable(__rendered);
      __rendered.dispose();
      __rendered = null;
    }

    withOwner(this, () -> {
      __rendered = new Computation(() -> switch __status {
        case Disposing | Disposed: 
          Placeholder.node();
        default:
          var node = try render() catch (e:Any) {
            this.tryToHandleWithBoundary(e);
            null;
          }
          if (__status != Rendering) invalidate();
          node ?? Placeholder.node();
      });
    });

    return __rendered?.peek() ?? Placeholder.node();
  }
  
  function __initialize():Void {
    __child = __render().createComponent();
    __child?.mount(this, __slot);
    withOwner(this, setup);
  }

  function __hydrate(cursor:Cursor):Void {
    __child = __render().createComponent();
    __child?.hydrate(cursor, this, __slot);
    withOwner(this, setup);
  }

  function __update():Void {
    __updateProps();
    // @todo: This solves a problem where sometimes the component fails
    // to render correctly, but it's not ideal. We'd much rather use
    // `__rendered?.peek()`. Investigate this more.
    __child = updateChild(this, __child, __render(), __slot);
    // __child = updateChild(this, __child, __rendered?.peek(), __slot);
  }

  function __validate():Void {
    __child = updateChild(this, __child, __rendered?.peek(), __slot);
  }

  function __dispose():Void {
    __rendered = null;
  }

  function __updateSlot(oldSlot, newSlot:Null<Slot>) {
    __child?.updateSlot(newSlot);
  }

  public function getRealNode() {
    var node:Null<Dynamic> = null;

    visitChildren(component -> {
      assert(node == null, 'Component has more than one nodes');
      node = component.getRealNode();
      true;
    });

    assert(node != null, 'Component does not have a node');

    return node;
  }

  public function visitChildren(visitor:(child:ComponentBase)->Bool) {
    if (__child != null) visitor(__child);
  }
}
