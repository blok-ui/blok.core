package blok;

import haxe.ds.Map;

@:nullSafety
class Context {
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
