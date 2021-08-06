package html;

import js.html.Node;
import js.html.Text;
import js.html.Element;
import js.Browser;
import blok.Component;
import blok.ConcreteManager;
import blok.Widget;

class ComponentManager implements ConcreteManager {
  final marker:js.html.Text = Browser.document.createTextNode('');
  final component:Component;

  public function new(component) {
    this.component = component;
  }

  public function toConcrete() {
    var concrete = component.getConcreteChildren();
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
  
  public function addConcreteChild(widget:Widget) {
    var els:Array<Element> = cast widget.getConcreteManager().toConcrete();

    if (marker.parentNode == null) {
      // Ignore -- we're at the initial render and this
      // will be handled by the parent Widget.
      return;
    }
    
    var children = component.getChildren();
    var prev = children.get(children.indexOf(widget) - 1);
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

    var prevWidget = component.getChildAt(pos);

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

  public function dispose() {
    marker.remove();
  }
}
