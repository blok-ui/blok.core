package blok.ui;

import blok.core.Scheduler;
import blok.ui.Effects;

abstract class Platform {
  public static function use(build) {
    return PlatformUser.of({ build: build });
  }

  final scheduler:Scheduler;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }
  
  abstract public function insertObject(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic):Void;
  abstract public function moveObject(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:()->Dynamic):Void;
  abstract public function removeObject(object:Dynamic, slot:Null<Slot>):Void;
  abstract public function updateObject(object:Dynamic, newWidget:ObjectWidget, oldWidget:Null<ObjectWidget>):Dynamic;
  abstract public function createObject(widget:ObjectWidget):Dynamic;
  abstract public function createPlaceholderObject(widget:Widget):Dynamic;

  public function mountRootWidget(widget:RootWidget, ?effect:Effect) {
    var element:RootElement = cast widget.createElement();
    if (effect != null) element.getEffects().register(effect);
    element.bootstrap();
    return element;
  }

  public function hydrateRootWidget(cursor:HydrationCursor, widget:RootWidget, ?effect:Effect) {
    var element:RootElement = cast widget.createElement();
    if (effect != null) element.getEffects().register(effect);
    element.hydrate(cursor, null);
    return element;
  }

  public function schedule(cb:()->Void) {
    scheduler.schedule(cb);
  }
}

class PlatformUser extends Component {
  @prop var build:(platform:Platform)->Widget;

  function render() {
    return build(platform);
  }
}
