package blok.core;

import haxe.ds.Map;

class Context<RealNode> {
  public final engine:Engine<RealNode>;
  public final scheduler:Scheduler;
  final data:Map<String, Dynamic> = [];
  final parent:Null<Context<RealNode>>;

  public function new(engine, ?scheduler, ?parent) {
    this.engine = engine;
    this.scheduler = if (scheduler == null) new DefaultScheduler() else scheduler;
    this.parent = parent;
  }

  public function get<T>(name:String, ?def:T):T {
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
    return new Context(engine, scheduler, this);
  }
}
