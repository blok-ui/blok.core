package blok.html.server;

import blok.debug.Debug;
import blok.adaptor.*;
import blok.node.*;
import blok.ui.*;

typedef ServerAdaptorOptions = {
  ?prefixTextWithMarker:Bool
};

class ServerAdaptor implements Adaptor {
  final options:ServerAdaptorOptions;

  public function new(?options) {
    this.options = options ?? { prefixTextWithMarker: true };
  }

	public function createNode(name:String, attrs:{}):Dynamic {
		return new Element(name, attrs);
	}

  public function createTextNode(value:String):Dynamic {
    return new TextNode(value, options?.prefixTextWithMarker ?? true);
  }

  public function createContainerNode(props:{}):Dynamic {
    return createNode('div', props);
  }

  public function createPlaceholderNode():Dynamic {
    return new TextNode('');
  }

  public function createCursor(object:Dynamic):Cursor {
    return new NodeCursor(object);
  }

  public function updateTextNode(object:Dynamic, value:String) {
    (object:TextNode).updateContent(value);
  }

  public function updateNodeAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Dynamic, ?isHydrating:Bool) {
    var el:Element = object;
    switch name {
      case 'className' | 'class':
        var oldNames = Std.string(oldValue ?? '').split(' ').filter(n -> n != null && n != '');
        var newNames = Std.string(value ?? '').split(' ').filter(n -> n != null && n != '');

        for (name in oldNames) {
          if (!newNames.contains(name)) {
            el.classList.remove(name);
          } else {
            newNames.remove(name);
          }
        }

        if (newNames.length > 0) {
          for (name in newNames) el.classList.add(name);
        }
      default:
        el.setAttribute(name, value);
    }
  }

  public function insertNode(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic) {
    var obj:Node = object;
    if (slot != null && slot.previous != null) {
      var relative:Node = slot.previous.getRealNode();
      var parent = relative.parent;
      if (parent != null) {
        var index = parent.children.indexOf(relative);
        parent.insert(index + 1, obj);
      } else {
        var parent:Node = findParent();
        assert(parent != null);
        parent.prepend(obj);
      }
    } else {
      var parent:Node = findParent();
      assert(parent != null);
      parent.prepend(obj);
    }
  }

  public function moveNode(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic) {
    var obj:Node = object;
    assert(to != null);

    if (from != null && !from.indexChanged(to)) {
      return;
    }

    if (to.previous == null) {
      var parent:Node = findParent();
      assert(parent != null);
      parent.prepend(object);
      return;
    }

    var relative:Node = to.previous.getRealNode();
    var parent = relative.parent;

    assert(parent != null);

    var index = parent.children.indexOf(relative);

    parent.insert(index + 1, obj);
  }

  public function removeNode(object:Dynamic, slot:Null<Slot>) {
    var obj:Node = object;
    obj.remove();
  }

	public function schedule(effect:() -> Void) {
    effect();
  }
}
