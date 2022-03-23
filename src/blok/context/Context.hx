package blok.context;

import haxe.ds.Map;
import blok.core.Disposable;
import blok.core.DisposableHost;
import blok.ui.Component;
import blok.ui.Widget;

/**
  A simple container for dependencies.
**/
final class Context implements Disposable implements DisposableHost {
  /**
    Allows `Context` to be used as a `ServiceResolver`.
  **/
  public static function from(context:Context) {
    return context;
  }

  /**
    Get access to the current Context instance in a Widget tree.

    If no Context is available, you can optionally provide your own
    Context instance to `fallback` to use instead. 
  **/
  public inline static function use(build, ?fallback, ?key) {
    return ContextUser.node({ build: build, fallback: fallback }, key);
  }

  final data:Map<String, Dynamic> = [];
  final parent:Null<Context>;
  var disposables:Array<Disposable> = [];

  public function new(?parent) {
    this.parent = parent;
  }

  /**
    Get a value from the Context. This method will recursively search
    parent Contexts until it finds a matching key. If no match is
    found, it will return null _or_ the value of `def`.
  **/
  public function get<T>(key:String, ?def:T):Null<T> {
    if (parent == null) {
      return data.exists(key) ? data.get(key) : def; 
    }
    return switch [ data.get(key), parent.get(key) ] {
      case [ null, null ]: def;
      case [ null, res ]: res;
      case [ res, _ ]: res;
    }
  }

  /**
    Set a value in this Context. If the value is `blok.core.Disposable`,
    it will be disposed when this Context is.
  **/
  public function set<T>(name:String, value:T) {
    data.set(name, value);
    if (value is Disposable) {
      addDisposable(cast value);
    }
  }

  /**
    Add a `blok.context.ServiceProvider`.
  **/
  public inline function addService<T:ServiceProvider>(service:T) {
    service.register(this);
  }

  /**
    Use a `blok.context.ServiceResolver` to find a matching value
    in this Context.
  **/
  public inline function getService<T>(resolver:ServiceResolver<T>):Null<T> {
    return resolver.from(this);
  }

  /**
    Create a child Context that uses _this_ Context as its parent.
  **/
  public function getChild() {
    var child = new Context(this);
    disposables.push(child);
    return child;
  }

  /**
    Dispose of this context and all disposable children.
  **/
  public function dispose() {
    var ds = disposables.copy();
    for (d in ds) d.dispose();
  }

  public function addDisposable(disposable:Disposable) {
    disposables.push(disposable);
  }
}

private class ContextUser extends Component {
  @prop var build:(context:Context)->Widget;
  @prop var fallback:Null<Context> = null;
  var context:Null<Context> = null;

  @before
  public function findContext() {
    context = switch findAncestorOfType(Provider) {
      case None:
        fallback;
      case Some(provider): 
        provider.getContext(); 
    }
  }

  public function getContext() {
    return context;
  }

  public function render() {
    return build(context);
  }
}
