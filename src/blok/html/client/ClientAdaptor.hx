package blok.html.client;

import js.Browser;
import js.html.Element;
import blok.debug.Debug;
import blok.adaptor.*;
import blok.ui.*;

using StringTools;

inline extern final svgNamespace = 'http://www.w3.org/2000/svg';

class ClientAdaptor implements Adaptor {
  final scheduler = new Scheduler();

  public function new() {}

  public function createNode(name:String, initialAttrs:{}):Dynamic {
    return name.startsWith('svg:')
      ? Browser.document.createElementNS(svgNamespace, name.substr(4)) 
      : Browser.document.createElement(name);
  }

  public function createTextNode(value:String):Dynamic {
    return Browser.document.createTextNode(value);
  }

  public function createContainerNode(props:{}):Dynamic {
    return createNode('div', props);
  }

  public function createPlaceholderNode():Dynamic {
    return createTextNode('');
  }

  public function createCursor(object:Dynamic):Cursor {
    return new ClientCursor(object);
  }

  public function updateTextNode(object:Dynamic, value:String) {
    (object:js.html.Text).textContent = value;
  }

  // @todo: Refactor this to be better  
  public function updateNodeAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Dynamic, ?isHydrating:Bool) {
    var el:Element = object;
    var isSvg = el.namespaceURI == svgNamespace;
    
    if (isHydrating == true) {
      name = getHtmlName(name);
      // Only bind events.
      // @todo: Setting events this way feels questionable.
      if (name.startsWith('on')) {
        var name = name.toLowerCase();
        if (value == null) {
          Reflect.setField(el, name, cast null);
        } else {
          Reflect.setField(el, name, value);
        }
      }
      return;
    }

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
          el.classList.add(...newNames);
        }
      case 'xmlns' if (isSvg): // skip
      case 'value' | 'selected' | 'checked' if (!isSvg):
        js.Syntax.code('{0}[{1}] = {2}', el, name, value);
      case _ if (!isSvg && js.Syntax.code('{0} in {1}', name, el)):
        js.Syntax.code('{0}[{1}] = {2}', el, name, value);
      case 'dataset':
        var map:Map<String, String> = value;
        for (key => value in map) {
          if (value == null) {
            Reflect.deleteField(el.dataset, key);  
          } else {
            Reflect.setField(el.dataset, key, value);
          }
        }
      default:
        name = getHtmlName(name);
        // @todo: Setting events this way feels questionable.
        if (name.startsWith('on')) {
          var name = name.toLowerCase();
          if (value == null) {
            Reflect.setField(el, name, cast null);
          } else {
            Reflect.setField(el, name, value);
          }
        } else if (value == null || (Std.is(value, Bool) && value == false)) {
          el.removeAttribute(name);
        } else if (Std.is(value, Bool) && value == true) {
          el.setAttribute(name, name);
        } else {
          el.setAttribute(name, value);
        }
    }
  }

  // @todo: Figure out how to use the @:html attributes for this instead.
  function getHtmlName(name:String) {
    if (name.startsWith('aria')) {
      return 'aria-' + name.substr(4).toLowerCase();
    }
    return name;
  }

  public function insertNode(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic) {
    var el:js.html.Element = object;
    if (slot != null && slot.previous != null) {
      var relative:js.html.Element = slot.previous.getRealNode();
      relative.after(el);
    } else {
      var parent:js.html.Element = findParent();
      assert(parent != null);
      parent.prepend(el);
    }
  }

  public function moveNode(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic) {
    var el:js.html.Element = object;

    if (to == null) {
      if (from != null) {
        removeNode(object, from);
      }
      return;
    }

    if (from != null && !from.indexChanged(to)) {
      return;
    }

    if (to.previous == null) {
      var parent:js.html.Element = findParent();
      assert(parent != null);
      parent.prepend(el);
      return;
    }

    var relative:js.html.Element = to.previous.getRealNode();
    assert(relative != null);
    relative.after(el);
  }

  public function removeNode(object:Dynamic, slot:Null<Slot>) {
    (object:Element).remove();
  }

  public function schedule(effect:() -> Void) {
    scheduler.schedule(effect);
  }
}
