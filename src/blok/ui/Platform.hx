package blok.ui;

import blok.core.Scheduler;

/**
  The Platform implements the way Blok apps are actually rendered,
  either through the DOM or some other target (along with a ConcreteManager
  and ConcreteWidgets).

  See libraries like `blok.platform.dom` or 'blok.platform.static`
  for implementations.
**/
@:nullSafety
abstract class Platform {
  /**
    Get the current Platform inside of a Widget tree.
  **/
  public inline static function use(build) {
    return PlatformUser.node({ build: build });
  }

  public final scheduler:Scheduler;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }

  /**
    Schedule an some action. This method will also give you access
    to an EffectManager to register callbacks that will run in the
    next frame (the API used by `@effect` mehods in Components).
  **/
  public function schedule(action) {
    var effects = createEffectManager();
    scheduler.schedule(() -> {
      action(effects.register);
      scheduler.schedule(() -> effects.dispatch());
    });
  }

  /**
    Bootstraps the app with the given ConcreteWidget. 
  **/
  public function mountRootWidget(root:ConcreteWidget, ?effect) {
    var effects = createEffectManager();
    root.initializeWidget(null, this);
    root.performUpdate(effects.register);
    if (effect != null) effects.register(effect);
    scheduler.schedule(() -> effects.dispatch());
  }

  /**
    Create ConcreteManagers that Components will use to manipulate this
    Platform's concrete target (such as the DOM). This 
    is the main method you need to implement if you're creating
    your own Platform. 
  **/
  abstract public function createManagerForComponent(component:Component):ConcreteManager;

  function createEffectManager():EffectManager {
    return new DefaultEffectManager();
  }
}

private class PlatformUser extends Component {
  @prop var build:(platform:Platform)->VNode;

  function render() {
    return build(getPlatform());
  }
}
