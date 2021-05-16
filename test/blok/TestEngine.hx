package blok;

import blok.core.Differ;
import blok.core.DefaultScheduler;
import blok.core.Scheduler;

class TestEngine implements Engine {
  final scheduler:Scheduler;
  
  public function new(?scheduler) {
    this.scheduler = scheduler == null 
      ? DefaultScheduler.getInstance() 
      : scheduler;
  }
  
  public function initialize(component:Component) {
    return Differ.initialize(component.__doRenderLifecycle(), this, component);
  }

  public function update(component:Component) {
    return Differ.diff(component.__doRenderLifecycle(), this, component, component.__renderedChildren);
  }

  public function schedule(cb:()->Void):Void {
    scheduler.schedule(cb);
  }
}
