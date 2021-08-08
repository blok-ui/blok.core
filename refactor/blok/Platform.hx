package blok;

@:nullSafety
abstract class Platform {
  public final scheduler:Scheduler;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }

  public function schedule(action) {
    var effects = createEffectManager();
    scheduler.schedule(() -> {
      action(effects.register);
      effects.dispatch();
    });
  }

  public function mountRootWidget(root:ConcreteWidget, ?effect) {
    var effects = createEffectManager();
    root.initializeWidget(null, this);
    root.performUpdate(effects.register);
    if (effect != null) effects.register(effect);
    effects.dispatch();
  }

  abstract public function createManagerForComponent(component:Component):ConcreteManager;
}

private inline function createEffectManager() {
  var effects:Array<()->Void> = [];
  return {
    register: effect -> effects.push(effect),
    dispatch: () -> for (effect in effects) effect()
  };
}
