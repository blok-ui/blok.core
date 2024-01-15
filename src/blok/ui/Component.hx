package blok.ui;

import blok.adaptor.Cursor;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.signal.Computation;
import blok.signal.Graph;
import blok.signal.Isolate;

using blok.boundary.BoundaryTools;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends ComponentBase {
  var __isolatedRender:Null<Isolate<VNode>>;
  var __child:Null<ComponentBase> = null;
  var __rendered:Null<Computation<Null<VNode>>> = null;

  abstract function setup():Void;
  abstract function render():Child;
  abstract function __updateProps():Void;
  
  function __createRendered() {
    return withOwnedValue(this, () -> {
      __isolatedRender = new Isolate(render);
      return new Computation(() -> switch __status {
        case Disposing | Disposed: 
          Placeholder.node();
        default:
          var node = try __isolatedRender() catch (e:Any) {
            __isolatedRender.cleanup();
            this.tryToHandleWithBoundary(e);
            null;
          }
          if (__status != Rendering) invalidate();
          node ?? Placeholder.node();
      });
    });
  }

  function __initialize():Void {
    assert(__rendered == null);
    __rendered = __createRendered();
    __child = __rendered.peek().createComponent();
    __child?.mount(this, __slot);
    withOwner(this, setup);
  }

  function __hydrate(cursor:Cursor):Void {
    assert(__rendered == null);
    __rendered = __createRendered();
    __child = __rendered.peek().createComponent();
    __child?.hydrate(cursor, this, __slot);
    withOwner(this, setup);
  }

  function __update():Void {
    assert(__rendered != null);
    __updateProps();
    __rendered.validateImmediately();
    __child = updateChild(this, __child, __rendered.peek(), __slot);
  }

  function __validate():Void {
    assert(__rendered != null);
    __child = updateChild(this, __child, __rendered.peek(), __slot);
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

  function __dispose():Void {
    __isolatedRender = null;
    __rendered = null;
  }
}
