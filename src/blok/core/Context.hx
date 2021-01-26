package blok.core;

import haxe.ds.Map;

class Context<RealNode> {
  public final engine:Engine<RealNode>;
  public final scheduler:Scheduler;

  public function new(engine, ?scheduler) {
    this.engine = engine;
    this.scheduler = if (scheduler == null) new DefaultScheduler() else scheduler;
  }
}
