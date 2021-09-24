package blok;

import haxe.ds.Map;
import blok.exception.NoProviderException;

@:nullSafety
final class Context implements Disposable {
  public inline static function use(build, ?fallback) {
    return ContextUser.node({ build: build, fallback: fallback });
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
      disposables.push(cast value);
    }
  }

  public inline function addService<T:ServiceProvider>(service:T) {
    service.register(this);
  }

  public inline function getService<T:ServiceProvider>(resolver:ServiceResolver<T>):Null<T> {
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
