package blok.ui;

import blok.core.Debug;
import blok.core.Scheduler;
import blok.ui.Effects;

typedef ScheduledUpdate = {
  public final invalidElements:Array<Element>;
  public final effects:Effects;
}

abstract class Platform {
  final scheduler:Scheduler;
  var currentUpdate:Null<ScheduledUpdate> = null;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }
  
  abstract public function insertObject(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic):Void;
  abstract public function moveObject(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:()->Dynamic):Void;
  abstract public function removeObject(object:Dynamic, slot:Null<Slot>):Void;
  abstract public function updateObject(object:Dynamic, newWidget:ObjectWidget, oldWidget:Null<ObjectWidget>):Dynamic;
  abstract public function createObjectForWidget(widget:ObjectWidget):Dynamic;
  abstract public function createPlaceholderObjectForWidget(widget:Widget):Dynamic;

  public function mountRootWidget(widget:RootWidget, ?effect:Effect) {
    var element:RootElement = cast widget.createElement();
    if (effect != null) scheduleEffects(effects -> effects.register(effect));
    element.bootstrap();
    return element;
  }

  public function scheduleEffects(cb:(effects:Effects) -> Void) {
    var update = getUpdate();
    Debug.assert(update != null);
    cb(update.effects);
  }

  public function scheduleForRebuild(element:Element) {
    var update = getUpdate();
    Debug.assert(update != null);
    if (!update.invalidElements.contains(element)) {
      update.invalidElements.push(element);
    }
  }

  function getUpdate() {
    if (currentUpdate == null) enqueueUpdate();
    return currentUpdate;
  }

  inline function enqueueUpdate() {
    Debug.assert(currentUpdate == null);
    
    currentUpdate = {
      invalidElements: [],
      effects: new Effects()
    };

    scheduler.schedule(() -> {
      var update = currentUpdate;
      currentUpdate = null;
      for (el in update.invalidElements) el.rebuild();
      update.effects.dispatch();
    });
  }
}
