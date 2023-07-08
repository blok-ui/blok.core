package blok.ui;

import blok.signal.Computation;
import blok.signal.Graph;
import blok.diffing.Differ;
import blok.debug.Debug;

@:autoBuild(blok.ui.AutoComponentBuilder.build())
abstract class AutoComponent extends Component {
  var __child:Null<Component> = null;
  var __rendered:Null<Computation<Null<VNode>>> = null;

  abstract function render():VNode;
  abstract function __updateProps():Void;

  function __render():VNode {
    if (__rendered != null) {
      __rendered.dispose();
      __rendered = null;
    }

    withOwner(this, () -> {
      __rendered = new Computation(() -> switch __status {
        case Disposing | Disposed: 
          null;
        default:
          var node = render();
          if (__status != Building) invalidate();
          node;
      });
    });

    return __rendered?.peek();
  }
  
  function __initialize():Void {
    __child = __render()?.createComponent();
    __child?.mount(this, __slot);
  }

  function __hydrate(cursor:Cursor):Void {
    __child = __render()?.createComponent();
    __child?.hydrate(cursor, this, __slot);
  }

  function __update():Void {
    __updateProps();
    __child = updateChild(this, __child, __rendered?.peek(), __slot);
  }

  function __validate():Void {
    __child = updateChild(this, __child, __rendered?.peek(), __slot);
  }

  function __dispose():Void {
    __rendered?.dispose();
    __rendered = null;
  }

  function __updateSlot(oldSlot, newSlot:Null<Slot>) {
    __child?.updateSlot(newSlot);
  }

  public function getRealNode() {
    var node:Null<Dynamic> = null;

    visitChildren(component -> {
      assert(node == null, 'Element has more than one nodes');
      node = component.getRealNode();
      true;
    });

    assert(node != null, 'Element does not have an node');

    return node;
  }

  public function visitChildren(visitor:(child:Component)->Bool) {
    if (__child != null) visitor(__child);
  }
}
