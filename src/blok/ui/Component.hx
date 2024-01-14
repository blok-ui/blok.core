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

  function __render():VNode {
    if (__rendered != null) {
      removeDisposable(__rendered);
      __rendered.dispose();
      __rendered = null;
    }

    if (__isolatedRender == null) {
      __isolatedRender = new Isolate(render);
    }

    withOwner(this, () -> {
      __rendered = new Computation(() -> switch __status {
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
    // @todo: The desired behavior here is that `__updateProps` *should*
    // cause the `__rendered` computation to update if anything changes.
    // However this seems to not always work as expected, especially
    // when `Suspenses` are involved (possibly some sort of race conditions?).
    // Just re-rendering everything seems to work, but it does negate
    // all the benefit conditional rendering would get us. Investigate 
    // this more -- we'd much rather use `__rendered?.peek()`.
    __child = updateChild(this, __child, __render(), __slot);
    // The desired code:
    // __child = updateChild(this, __child, __rendered?.peek(), __slot);
  }

  function __validate():Void {
    __child = updateChild(this, __child, __rendered?.peek(), __slot);
  }

  function __dispose():Void {
    __isolatedRender?.dispose();
    __isolatedRender = null;
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
