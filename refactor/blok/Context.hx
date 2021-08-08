package blok;

import haxe.ds.Map;
import blok.exception.NoProviderException;

@:nullSafety
final class Context {
  public inline static function use(build, ?fallback) {
    return ContextUser.node({ build: build, fallback: fallback });
  }

  final data:Map<String, Dynamic> = [];
  final parent:Null<Context>;

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
  }
  
  public function getChild() {
    return new Context(this);
  }
}

private final class ContextUser extends Component {
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
