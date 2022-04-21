package blok.ui;

import blok.core.Debug;
import blok.core.Scheduler;

@:allow(blok.ui)
abstract class Platform {
  public static function use(build) {
    return PlatformUser.of({ build: build });
  }

  final scheduler:Scheduler;
  var root:RootElement;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }
  
  abstract public function insertObject(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic):Void;
  abstract public function moveObject(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:()->Dynamic):Void;
  abstract public function removeObject(object:Dynamic, slot:Null<Slot>):Void;
  abstract public function updateObject(object:Dynamic, newWidget:ObjectWidget, oldWidget:Null<ObjectWidget>):Dynamic;
  abstract public function createObject(widget:ObjectWidget):Dynamic;
  abstract public function createPlaceholderObject(widget:Widget):Dynamic;

  public function mountRootWidget(widget:RootWidget) {
    Debug.assert(root == null);

    root = cast widget.createElement();
    root.bootstrap();
    return root;
  }

  public function hydrateRootWidget(cursor:HydrationCursor, widget:RootWidget) {
    Debug.assert(root == null);
    
    root = cast widget.createElement();
    root.hydrate(cursor, null);
    return root;
  }

  public function getRootElement() {
    Debug.assert(root != null);

    return root;
  }

  public function schedule(cb:()->Void) {
    scheduler.schedule(cb);
  }

  public function requestRebuild(element:Element) {
    Debug.assert(root != null);

    root.requestRebuild(element);
  }
}

class PlatformUser extends Component {
  @prop var build:(platform:Platform)->Widget;

  function render() {
    return build(platform);
  }
}
