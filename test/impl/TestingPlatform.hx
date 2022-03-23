package impl;

import blok.core.Debug;
import blok.core.DefaultScheduler;
import blok.ui.Slot;
import blok.ui.Widget;
import blok.ui.Platform;

class TestingPlatform extends Platform {
  public static function mount(?child:Widget, ?handler:(result:TestingObject)->Void):TestingRootElement {
    var platform = new TestingPlatform(DefaultScheduler.getInstance());
    var object = new TestingObject('');
    return cast platform.mountRootWidget(new TestingRootWidget(object, platform, child), () -> {
      if (handler != null) handler(object);
    });
  }

  public function insert(object:Dynamic, slot:Null<Slot>, findParent:()->Dynamic) {
    var obj:TestingObject = object;
    if (slot != null && slot.previous != null) {
      var relative:TestingObject = slot.previous.getObject();
      relative.parent.insert(slot.index, obj);
    } else {
      var parent:TestingObject = findParent();
      Debug.assert(parent != null);
      parent.append(obj);
    }
  }

  public function move(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:()->Dynamic) {
    var obj:TestingObject = object;
    if (from != null && to != null) {
      if (from.index == to.index) return;
    }
    
    Debug.assert(to != null);

    if (to.previous == null) {
      var parent:TestingObject = findParent();
      Debug.assert(parent != null);
      parent.append(object);
      return;
    }

    var relative:TestingObject = to.previous.getObject();
    relative.parent.insert(to.index, obj);
  }

  public function remove(object:Dynamic, slot:Null<Slot>) {
    var obj:TestingObject = object;
    obj.remove();
  }
}
