package html;

import blok.tools.ObjectTools;
import js.html.Element;
import blok.VNode;
import blok.Differ;
import blok.ConcreteWidget;
import blok.Widget;
import blok.WidgetType;

using Reflect;

class ElementWidget<Attrs:{}> extends ConcreteWidget {
  final el:Element;
  final type:WidgetType;
  var attrs:Attrs;
  var children:Array<VNode>;

  public function new(el, type, attrs, children) {
    this.el = el;
    this.type = type;
    this.attrs = attrs;
    this.children = children;
  }

  override function __initHooks() {
    ObjectTools.diffObject(
      {},
      attrs,
      updateNodeAttribute.bind(el)
    );
  }

  public function updateAttrs(attrs:Attrs) {
    var changed = ObjectTools.diffObject(
      this.attrs,
      attrs,
      updateNodeAttribute.bind(el)
    );
    if (changed > 0) {
      __status = WidgetInvalid;
      this.attrs = attrs;
    }
  }

  public function setChildren(newChildren:Array<VNode>) {
    __status = WidgetInvalid;
    children = newChildren;
  }

  public function getWidgetType() {
    return type;
  }

  public function toConcrete() {
    return [ el ];
  }

  public function getFirstConcreteChild() {
    return el;
  }

  public function getLastConcreteChild() {
    return el;
  }

  public function toString() {
    return el.outerHTML;
  }

  public function __performUpdate(registerEffect:(effect:()->Void)->Void):Void {
    Differ.diffChildren(this, children, __platform, registerEffect);
  }

  public function addConcreteChild(widget:Widget) {
    var els:Array<Element> = cast widget.getConcreteManager().toConcrete();    
    for (child in els) el.appendChild(child);
  }

  public function insertConcreteChildAt(pos:Int, widget:Widget) {
    var prevWidget = getChildAt(pos);

    if (prevWidget == null) {
      addConcreteChild(widget);
      return;
    }

    var prev:Element = prevWidget.getConcreteManager().getLastConcreteChild();
    var els:Array<Element> = cast widget.getConcreteManager().toConcrete();

    for (child in els) {
      el.insertBefore(child, prev.nextSibling);
      prev = child;
    }
  }

  public function moveConcreteChildTo(pos:Int, child:Widget):Void {
    insertConcreteChildAt(pos, child);
  }

  public function removeConcreteChild(widget:Widget):Void {
    var els:Array<Element> = cast widget.getConcreteManager().toConcrete();
    for (child in els) el.removeChild(child);
  }

  static function updateNodeAttribute(el:Element, name:String, oldValue:Dynamic, newValue:Dynamic):Void {
     switch name {
      case 'ref' | 'key': 
        // noop
      case 'className':
        updateNodeAttribute(el, 'class', oldValue, newValue);
      // case 'xmlns' if (isSvg): // skip
      case 'value' | 'selected' | 'checked':
        js.Syntax.code('{0}[{1}] = {2}', el, name, newValue);
      case _ if (js.Syntax.code('{0} in {1}', name, el)):
        js.Syntax.code('{0}[{1}] = {2}', el, name, newValue);
      default:
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
}
