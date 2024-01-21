package blok.ui;

import blok.adaptor.Cursor;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.signal.Computation;
import blok.signal.Owner;
import blok.signal.Isolate;

using blok.boundary.BoundaryTools;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends ComponentBase {
  @:noCompletion var __isolatedRender:Null<Isolate<VNode>> = null;
  @:noCompletion var __child:Null<ComponentBase> = null;
  @:noCompletion var __rendered:Null<Computation<Null<VNode>>> = null;

  abstract function setup():Void;
  abstract function render():Child;
  @:noCompletion abstract function __updateProps():Void;
  
  @:noCompletion function __createRendered() {
    // @todo: With new new Signal model, we probably don't need the 
    // Isolate anymore?
    return Owner.with(this, () -> {
      __isolatedRender = new Isolate(render);
      return Computation.eager(() -> switch __status {
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

  @:noCompletion function __initialize():Void {
    assert(__rendered == null);
    __rendered = __createRendered();
    __child = __rendered.peek().createComponent();
    __child?.mount(this, __slot);
    Owner.with(this, setup);
  }

  @:noCompletion function __hydrate(cursor:Cursor):Void {
    assert(__rendered == null);
    __rendered = __createRendered();
    __child = __rendered.peek().createComponent();
    __child?.hydrate(cursor, this, __slot);
    Owner.with(this, setup);
  }

  @:noCompletion function __update():Void {
    assert(__rendered != null);
    __updateProps();
    __child = updateChild(this, __child, __rendered.peek(), __slot);
  }

  @:noCompletion function __validate():Void {
    assert(__rendered != null);
    __child = updateChild(this, __child, __rendered.peek(), __slot);
  }

  @:noCompletion function __updateSlot(oldSlot, newSlot:Null<Slot>) {
    __child?.updateSlot(newSlot);
  }

  public function getRealNode() {
    var node:Null<Dynamic> = null;

    visitChildren(component -> {
      assert(node == null, 'Component has more than one real nodes');
      node = component.getRealNode();
      true;
    });

    assert(node != null, 'Component does not have a real node');

    return node;
  }

  public function visitChildren(visitor:(child:ComponentBase)->Bool) {
    if (__child != null) visitor(__child);
  }

  @:noCompletion function __dispose():Void {
    // __isolatedRender = null;
    __rendered = null;
  }
}
