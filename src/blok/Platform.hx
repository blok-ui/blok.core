package blok;

@:nullSafety
abstract class Platform {
  public final scheduler:Scheduler;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }

  public function schedule(action) {
    var effects = EffectManager.createEffectManager();
    scheduler.schedule(() -> {
      action(effects.register);
      scheduler.schedule(() -> effects.dispatch());
    });
  }

  public function mountRootWidget(root:ConcreteWidget, ?effect) {
    var effects = EffectManager.createEffectManager();
    root.initializeWidget(null, this);
    root.performUpdate(effects.register);
    if (effect != null) effects.register(effect);
    scheduler.schedule(() -> effects.dispatch());
  }

  abstract public function createManagerForComponent(component:Component):ConcreteManager;
}
