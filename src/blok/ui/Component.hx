package blok.ui;

import blok.core.Debug;

@:autoBuild(blok.ui.ComponentBuilder.build())
abstract class Component extends Element {
  var childElement:Null<Element> = null;
  var currentRevision:Int = 0;
  var lastRevision:Int = 0;

  abstract function render():Widget;
  abstract function updateWidget(props:Dynamic):Void;

  override function mount(parent:Element, ?slot:Slot) {
    super.mount(parent, slot);
    performFirstBuild();
  }

  override function update(widget:Widget) {
    Debug.assert(lifecycle != Building);
    // @todo: We need to rethink this -- right now, we basically create three
    // widgets per update.
    updateWidget((cast widget:ComponentWidget<Dynamic>).props);
    if (shouldInvalidate()) performBuild();
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

  function shouldInvalidate():Bool {
    return true;
    // return currentRevision > lastRevision;
  }

  function updateWidgetAndInvalidateElement(props:Dynamic) {
    Debug.assert(status == Active);
    Debug.assert(lifecycle != Building);
    updateWidget(props);
    if (shouldInvalidate()) invalidateElement();
  }
}
