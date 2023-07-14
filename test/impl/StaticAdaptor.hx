package impl;

import blok.debug.Debug;
import blok.adaptor.*;
import blok.node.*;
import blok.ui.*;

typedef StaticAdaptorOptions = {
  ?prefixTextWithMarker:Bool
};

class StaticAdaptor implements Adaptor {
  final options:StaticAdaptorOptions;

  public function new(?options) {
    this.options = options ?? { prefixTextWithMarker: true };
  }

	public function createContainerNode(attrs:{}):Dynamic {
		return createCustomNode('div', attrs);
	}

	public function createButtonNode(attrs:{}):Dynamic {
		return createCustomNode('button', attrs);
	}

	public function createInputNode(attrs:{}):Dynamic {
		return createCustomNode('input', attrs);
	}

  public function createCustomNode(name:String, initialAttrs:{}):Dynamic {
    return new Element(name, initialAttrs);
  }

  public function createTextNode(value:String):Dynamic {
    return new TextNode(value, options?.prefixTextWithMarker ?? true);
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

  public function updateNodeAttribute(object:Dynamic, name:String, value:Dynamic, ?isHydrating:Bool) {
    (object:Element).setAttribute(name, value);
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
