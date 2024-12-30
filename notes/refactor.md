# Refactor

This will be a push to simplify and flatten things a bit, mostly by splitting stuff up as much as possible into composable chunks. Additionally, rendering will be handled outside Views by a parent Renderer class, making the Adaptor deprecated.

```haxe
interface Node {
  // This is the VNode
}

interface Primitive {
  public function get():Maybe<Dynamic>;
}

interface Children {
  public function each(handler:(child:Child) -> Bool):Void;
  public function find<T>(handler:(child:Child) -> Maybe<T>):Maybe<T>;
}

interface View extends Disposable extends DisposableHost {
  public var node(get, never):Node;
  public var parent(get, never):Maybe<View>;
  public var slot(get, never):Maybe<Slot>;
  public var children(get, never):Children;
  public var primitive(get, never):Primitive;

  public function mount(parent:Maybe<View>, slot:Maybe<Slot>):Void;
  public function hydrate(parent:Maybe<View>, slot:Maybe<Slot>):Void;
  public function update():Void;
  public function move(slot:Maybe<Slot>):Void;
}
```

Implementations are something like:

```haxe
class ProxyPrimitive implements Primitive {
  final view:View;

  public function new(view) {
    this.view = view;
  }

  public function get() {
    return view.children.find(child -> child.primitive.get());
  }
}

class ProxyChild implements Children {
  var child:Maybe<View>;

  public function new(child) {
    this.child = child;
  }

  public function set(child) {
    this.child = child;
  }

  public function each(handler:(child:Child) -> Bool):Void {
    child.inspect(handler);
  }

  public function find<T>(handler:(child:Child) -> Maybe<T>):Maybe<T> {
    return child.map(handler);
  }
}

class ProxyNode implements Node {
  // todo
}

@:forward
abstract ProxyRenderer(Computation<View>) {
  public inline function new(view:View, render:()->View) {
    var isolate = new Isolate(render);
    // Pretend we have a Lifecycle class set up:
    this = Computation.untracked(() -> switch view.lifecycle.status {
      case Disposing | Disposed:
        Placeholder.node();
      default:
        var node = try isolate() catch (e:Any) {
          isolate.cleanup();
          view.tryToHandleWithBoundary(e);
          null;
        }
        if (view.lifecycle.status != Rendering) view.invalidate();
        node ?? Placeholder.node();
    });
  }
}

abstract class ProxyView implements View {
  public var node(get, never):Node;
  var __node:ProxyNode;
  function get_node():Node return __node;

  public var parent(get, never):Maybe<View>;
  var __parent:Maybe<View>;
  function get_parent():Node return __parent;

  public var slot(get, never):Maybe<Slot>;
  var __slot:Maybe<Slot>;
  function get_slot():Node return __slot;

  public var children(get, never):Children;
  var __children:ProxyChild;
  function get_children():Children return __children;

  public var primitive(get, never):Primitive;
  var __primitive:ProxyPrimitive;
  function get_primitive():Children return __primitive;

  var __renderer:Null<ProxyRenderer> = null;

  public function new(node) {
    __node = node;
    __child = new ProxyChild(None);
    __primitive = new ProxyPrimitive(this);
  }

  abstract function setup():Void;
  abstract function render():Node;

  public function mount(parent:Maybe<View>, slot:Maybe<Slot>):Void {
    __parent = parent;
    __slot = slot;
    Owner.capture(this, {
      __renderer = new ProxyRenderer(this, render);
  
      var child = __renderer.peek().createView();
      child.mount(this, __slot);
  
      __children.set(child);
      setup();
    });
  }

  public function hydrate(parent:Maybe<View>, slot:Maybe<Slot>):Void [
    // todo
  ]

  public function update():Void {
    // todo
  }

  public function move(slot:Maybe<Slot>):Void {
    __children.each(child -> {
      child.move(slot);
      false;
    });
  }
}
```

Etc.
