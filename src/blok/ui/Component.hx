package blok.ui;

import blok.core.Debug;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends Element {
  var childElement:Null<Element> = null;

  abstract function render():Widget;

  override function mount(parent:Element, ?slot:Slot) {
    super.mount(parent, slot);
    performFirstBuild();
  }

  override function update(widget:Widget) {
    Debug.assert(lifecycle != Building);
    if ((cast this.widget:ComponentWidget<Dynamic>).hasChanged(widget)) {
      this.widget = widget;
      performBuild();
    }
    lifecycle = Valid;
  }

  function rebuildElement() {
    if (lifecycle != Invalid) return;
    performBuild();
  }

  function visitChildren(visitor:ElementVisitor) {
    if (childElement != null) visitor.visit(childElement);
  }

  function performRender() {
    return render();
  }

  function performFirstBuild() {
    performBuild();
  }

  function performBuild() {
    Debug.assert(lifecycle != Building);
    lifecycle = Building;
    childElement = updateChild(childElement, performRender(), slot);
    lifecycle = Valid;
  }

  function updateWidgetAndInvalidateElement(props:Dynamic) {
    Debug.assert(status == Active);
    Debug.assert(lifecycle != Building);
    var comp:ComponentWidget<Dynamic> = cast widget;
    var newWidget = comp.withProperties(props);
    if (comp.hasChanged(newWidget)) {
      widget = newWidget;
      invalidateElement();
    } 
  }
}
