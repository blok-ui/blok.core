package blok.framework;

import blok.core.Debug;

@:autoBuild(blok.framework.ComponentBuilder.build())
abstract class Component extends Element {
  var childElement:Null<Element> = null;
  var currentRevision:Int = 0;
  var lastRevision:Int = 0;

  abstract function render():Widget;
  abstract function updateWidget(props:Dynamic):Void;

  override function mount(parent:Element, ?slot:Slot) {
    super.mount(parent, slot);
    performBuild();
  }

  override function update(widget:Widget) {
    lifecycle = Valid;
    updateWidget(widget);
    if (shouldInvalidate()) performBuild();
  }

  override function rebuildElement() {
    if (lifecycle != Invalid) return;
    Debug.assert(lifecycle != Building);
    performBuild();
  }

  function visitChildren(visitor:ElementVisitor) {
    if (childElement != null) visitor.visit(childElement);
  }

  function performRender() {
    return render();
  }

  function performBuild() {
    lifecycle = Building;
    childElement = updateChild(childElement, performRender(), slot);
    lifecycle = Valid;
  }

  function shouldInvalidate():Bool {
    return currentRevision > lastRevision;
  }

  function updateWidgetAndInvalidateElement(props:Dynamic) {
    Debug.assert(status == Active);
    Debug.assert(lifecycle != Building);
    updateWidget(props);
    if (shouldInvalidate()) invalidateElement();
  }
}
