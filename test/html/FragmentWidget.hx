package html;

import js.html.Node;
import blok.Differ;
import blok.VNode;
import blok.Widget;
import js.Browser;
import js.html.Element;
import blok.WidgetType;
import blok.WidgetType.getUniqueTypeId;
import blok.ConcreteWidget;

class FragmentWidget extends ConcreteWidget {
  public static final type:WidgetType = getUniqueTypeId();

  final marker = Browser.document.createTextNode('');
  var children:Array<VNode>;

  public function new(children) {
    this.children = children;
  }
  
  public function getLength() {
    return toConcrete().length;
  }
  
  public function getWidgetType() {
    return type;
  }

  public function setChildren(children) {
    __status = WidgetInvalid;
    this.children = children;
  }

  public function toConcrete() {
    var concrete = getConcreteChildren();
    var els:Array<Element> = [ cast marker ];
    
    for (child in concrete) {
      els = els.concat(cast child.toConcrete());
    }

    return els;
  }

  public function getFirstConcreteChild() {
    return marker;
  }

  public function getLastConcreteChild() {
    return toConcrete().pop();
  }

  public function toString() {
    return toConcrete().map(el -> el.innerHTML).join('');
  }

  public function __performUpdate(registerEffect:(effect:()->Void)->Void):Void {
    Differ.diffChildren(this, children, __platform, registerEffect);
  }

  public function addConcreteChild(widget:Widget) {
    if (marker.parentNode == null) {
      // Ignore -- we're at the initial render and this
      // will be handled by the parent Widget.
      return;
    }
    
    var els:Array<Element> = cast widget.getConcreteManager().toConcrete();
    var prev = __children.get(__children.indexOf(widget) - 1);
    var lastEl:Node = prev == null 
      ? marker
      : prev.getConcreteManager().getLastConcreteChild();
    var last = lastEl.nextSibling;

    for (child in els) {
      marker.parentNode.insertBefore(child, last);
    }
  }

  public function insertConcreteChildAt(pos:Int, widget:Widget) {
    var el = marker.parentNode;

    if (el == null) {
       // Ignore -- we're at the initial render and this
       // will be handled by the parent Widget.
      return;
    }

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
    for (child in els) child.remove();
  }

  override function dispose() {
    super.dispose();
    marker.remove();
  }
}
