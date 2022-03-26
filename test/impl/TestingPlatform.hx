package impl;

import blok.core.Debug;
import blok.core.DefaultScheduler;
import blok.ui.Slot;
import blok.ui.Widget;
import blok.ui.Platform;
import blok.ui.ObjectWidget;

class TestingPlatform extends Platform {
  public static function mount(?child:Widget, ?handler:(result:TestingObject)->Void):TestingRootElement {
    var platform = new TestingPlatform(DefaultScheduler.getInstance());
    var object = new TestingObject('');
    return cast platform.mountRootWidget(new TestingRootWidget(object, platform, child), () -> {
      if (handler != null) handler(object);
    });
  }

  public function insertObject(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic) {
    var obj:TestingObject = object;
    if (slot != null && slot.previous != null) {
      var relative:TestingObject = slot.getPreviousObject();
      var parent = relative.parent;
      var index = parent.children.indexOf(relative);
      parent.insert(index + 1, obj);
    } else {
      var parent:TestingObject = findParent();
      Debug.assert(parent != null);
      parent.append(obj);
    }
  }

  public function moveObject(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:()->Dynamic) {
    var obj:TestingObject = object;
    
    Debug.assert(to != null);

    if (to.previous == null) {
      var parent:TestingObject = findParent();
      Debug.assert(parent != null);
      parent.append(object);
      return;
    }

    var relative:TestingObject = to.getPreviousObject();
    var parent = relative.parent;
    var index = parent.children.indexOf(relative);

    parent.insert(index + 1, obj);
  }

  public function removeObject(object:Dynamic, slot:Null<Slot>) {
    var obj:TestingObject = object;
    obj.remove();
  }

  public function updateObject(object:Dynamic, newWidget:ObjectWidget, oldWidget:Null<ObjectWidget>):Dynamic {
    return newWidget.updateObject(object, oldWidget);
  }

  public function createObjectForWidget(widget:ObjectWidget):Dynamic {
    return widget.createObject();
  }

  public function createPlaceholderObjectForWidget(widget:Widget):Dynamic {
    return new TestingObject('');
  }
}
