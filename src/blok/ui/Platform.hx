package blok.ui;

import blok.core.Scheduler;

/**
  The Platform implements the way Blok apps are actually rendered,
  either through the DOM or some other target (along with a ConcreteManager
  and ConcreteWidgets).

  See libraries like `blok.platform.dom` or 'blok.platform.static`
  for implementations.
**/
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
    Schedule some action. The provided callback will also recieve
    a 'blok.ui.Effect` that can be used to add additonal effects 
    which will be scheduled for the subsequent frame. 
    
    Widgets use this internally to handle things like `@effect` methods.
  **/
  public function schedule(action:(effects:Effect)->Void) {
    var effects = Effect.createTrigger();
    scheduler.schedule(() -> {
      action(effects);
      scheduler.schedule(() -> effects.dispatch());
    });
  }

  /**
    Bootstraps the app with the given ConcreteWidget. 
  **/
  public function mountRootWidget(root:ConcreteWidget, ?effect) {
    var effects = Effect.createTrigger();
    root.initializeWidget(null, this);
    root.performUpdate(effects);
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
}

private class PlatformUser extends Component {
  @prop var build:(platform:Platform)->VNode;

  function render() {
    return build(getPlatform());
  }
}
