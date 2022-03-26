package blok.ui;

import blok.ui.Effects;
import blok.core.Scheduler;

abstract class Platform {
  var invalidElements:Array<Element> = [];
  var rebuildScheduled:Bool = false;
  var effects:Null<Effects> = null;
  final scheduler:Scheduler;

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
    if (effects == null) {
      effects = new Effects();
      scheduler.schedule(() -> {
        effects.dispatch();
        effects = null;
      });
    }
    cb(effects);
  }

  public function scheduleForRebuild(element:Element) {
    if (invalidElements.contains(element)) return;
    invalidElements.push(element);
    if (!rebuildScheduled) {
      rebuildScheduled = true;
      scheduler.schedule(rebuild);
    }
  }

  function rebuild() {
    var elements = invalidElements.copy();
    
    invalidElements = [];
    rebuildScheduled = false;

    for (el in elements) el.rebuild();
  }
}
