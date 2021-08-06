package blok;

@:nullSafety
abstract class Platform {
  public final scheduler:Scheduler;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }

  public function schedule(action) {
    var effects:Array<()->Void> = [];
    function registerEffect(effect:()->Void) effects.push(effect);

    scheduler.schedule(() -> {
      action(registerEffect);
      for (effect in effects) effect();
    });
  }

  abstract public function createManagerForComponent(component:Component):ConcreteManager;
}
