package blok.html.server;

import blok.adaptor.*;
import blok.core.Scheduler;
import blok.debug.Debug;
import blok.node.*;
import blok.ui.*;

using StringTools;

typedef ServerAdaptorOptions = {
  ?prefixTextWithMarker:Bool
};

class ServerAdaptor implements Adaptor {
  final scheduler:Scheduler;
  final options:ServerAdaptorOptions;

  public function new(?options) {
    this.options = options ?? { prefixTextWithMarker: true };
    this.scheduler = getCurrentScheduler().orThrow('No scheduler available');
  }

	public function createNode(name:String, attrs:{}):Dynamic {
    if (name.startsWith('svg:')) name = name.substr(4);
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
        el.setAttribute(getHtmlName(name), value);
    }
  }

  public function insertNode(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic) {
    var node:Node = object;
    if (slot != null && slot.previous != null) {
      var relative:Node = slot.previous.getRealNode();
      var parent = relative.parent;
      if (parent != null) {
        var index = parent.children.indexOf(relative);
        parent.insert(index + 1, node);
      } else {
        var parent:Node = findParent();
        assert(parent != null);
        parent.prepend(node);
      }
    } else {
      var parent:Node = findParent();
      assert(parent != null);
      parent.prepend(node);
    }
  }

  public function moveNode(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic) {
    var node:Node = object;
    assert(to != null);

    if (to == null) {
      if (from != null) {
        removeNode(object, from);
      }
      return;
    }

    if (from != null && !from.changed(to)) {
      return;
    }

    if (to.previous == null) {
      var parent:Node = findParent();
      assert(parent != null);
      parent.prepend(node);
      return;
    }

    var relative:Node = to.previous.getRealNode();
    var parent = relative.parent;

    assert(parent != null);

    var index = parent.children.indexOf(relative);

    parent.insert(index + 1, node);
  }

  public function removeNode(object:Dynamic, slot:Null<Slot>) {
    var node:Node = object;
    node.remove();
  }

	public function schedule(effect:() -> Void) {
    scheduler.schedule(effect);
  }
}

// @todo: Figure out how to use the @:html attributes for this instead.
function getHtmlName(name:String) {
  if (name.startsWith('aria')) {
    return 'aria-' + name.substr(4).toLowerCase();
  }
  return name;
}
