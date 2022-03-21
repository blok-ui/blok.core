package blok.framework.platform;

import js.Browser;
import blok.core.ObjectTools;

using StringTools;

class HtmlObjectElement extends ObjectElement {
  public function new(widget:HtmlObjectWidget) {
    super(widget);
  }

  public function createObject():Dynamic {
    var concrete:HtmlObjectWidget = cast widget;
    var el = Browser.document.createElement(concrete.tag);
    ObjectTools.diffObject(
      {},
      concrete.attrs,
      updateNodeAttribute.bind(el)
    );
    return el;
  }

  public function updateObject(?oldWidget:Widget) {
    var el:js.html.Element = object;
    var oldConcrete:HtmlObjectWidget = cast oldWidget;
    var concrete:HtmlObjectWidget = cast widget;
    ObjectTools.diffObject(
      oldConcrete != null ? oldConcrete.attrs : {},
      concrete.attrs,
      updateNodeAttribute.bind(el)
    );
  }
}

private function updateNodeAttribute(el:js.html.Element, name:String, oldValue:Dynamic, newValue:Dynamic):Void {
  var isSvg = false;
  switch name {
    case 'ref' | 'key': 
      // noop
    case 'className':
      updateNodeAttribute(el, 'class', oldValue, newValue);
    case 'xmlns' if (isSvg): // skip
    case 'value' | 'selected' | 'checked' if (!isSvg):
      js.Syntax.code('{0}[{1}] = {2}', el, name, newValue);
    case _ if (!isSvg && js.Syntax.code('{0} in {1}', name, el)):
      js.Syntax.code('{0}[{1}] = {2}', el, name, newValue);
    default:
      name = getHtmlName(name);
      if (name.charAt(0) == 'o' && name.charAt(1) == 'n') {
        var name = name.toLowerCase();
        if (newValue == null) {
          Reflect.setField(el, name, null);
        } else {
          Reflect.setField(el, name, newValue);
        }
        // var ev = key.substr(2).toLowerCase();
        // el.removeEventListener(ev, oldValue);
        // if (newValue != null) el.addEventListener(ev, newValue);
      } else if (newValue == null || (Std.is(newValue, Bool) && newValue == false)) {
        el.removeAttribute(name);
      } else if (Std.is(newValue, Bool) && newValue == true) {
        el.setAttribute(name, name);
      } else {
        el.setAttribute(name, newValue);
      }
  }
}

// @todo: come up with a way to do this automatically with the @:html
//        metadata from blok.core.html.
private function getHtmlName(name:String) {
  if (name.startsWith('aria')) {
    return 'aria-' + name.substr(4).toLowerCase();
  }
  return name;
}
