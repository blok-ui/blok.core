package blok.context;

import haxe.ds.Map;
import blok.exception.NoProviderException;
import blok.core.Disposable;
import blok.core.DisposableHost;
import blok.ui.Component;
import blok.ui.VNode;

@:nullSafety
final class Context implements Disposable implements DisposableHost {
  public inline static function use(build, ?fallback, ?key) {
    return ContextUser.node({ build: build, fallback: fallback }, key);
  }

  final data:Map<String, Dynamic> = [];
  final parent:Null<Context>;
  var disposables:Array<Disposable> = [];

  public function new(?parent) {
    this.parent = parent;
  }

  public function get<T>(name:String, ?def:T):Null<T> {
    if (parent == null) {
      return data.exists(name) ? data.get(name) : def; 
    }
    return switch [ data.get(name), parent.get(name) ] {
      case [ null, null ]: def;
      case [ null, res ]: res;
      case [ res, _ ]: res;
    }
  }

  public function set<T>(name:String, value:T) {
    data.set(name, value);
    if (value is Disposable) {
      addDisposable(cast value);
    }
  }

  public inline function addService<T:ServiceProvider>(service:T) {
    service.register(this);
  }

  public inline function getService<T>(resolver:ServiceResolver<T>):Null<T> {
    return resolver.from(this);
  }

  public function getChild() {
    var child = new Context(this);
    disposables.push(child);
    return child;
  }

  public function dispose() {
    var ds = disposables.copy();
    for (d in ds) d.dispose();
  }

  public function addDisposable(disposable:Disposable) {
    disposables.push(disposable);
  }
}

private class ContextUser extends Component {
  @prop var build:(context:Context)->VNode;
  @prop var fallback:Null<Context> = null;
  var context:Null<Context> = null;

  @before
  public function findContext() {
    context = switch findParentOfType(Provider) {
      case None if (fallback != null):
        fallback;
      case None:
        throw new NoProviderException(this); 
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
