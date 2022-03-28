package blok.render;

import blok.core.Debug;
import blok.ui.Slot;
import blok.ui.ObjectWidget;

abstract class Platform extends blok.ui.Platform {
  public function insertObject(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic) {
    var obj:Object = object;
    if (slot != null && slot.previous != null) {
      var relative:Object = slot.previous.getObject();
      var parent = relative.parent;
      var index = parent.children.indexOf(relative);
      parent.insert(index + 1, obj);
    } else {
      var parent:Object = findParent();
      Debug.assert(parent != null);
      parent.append(obj);
    }
  }

  public function moveObject(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:()->Dynamic) {
    var obj:Object = object;
    
    Debug.assert(to != null);

    if (from != null && !from.indexChanged(to)) {
      return;
    }

    if (to.previous == null) {
      var parent:Object = findParent();
      Debug.assert(parent != null);
      parent.append(object);
      return;
    }

    var relative:Object = to.previous.getObject();
    var parent = relative.parent;
    var index = parent.children.indexOf(relative);

    parent.insert(index + 1, obj);
  }

  public function removeObject(object:Dynamic, slot:Null<Slot>) {
    var obj:Object = object;
    obj.remove();
  }

  public function updateObject(object:Dynamic, newWidget:ObjectWidget, oldWidget:Null<ObjectWidget>):Dynamic {
    return newWidget.updateObject(object, oldWidget);
  }

  public function createObject(widget:ObjectWidget):Dynamic {
    return widget.createObject();
  }
}