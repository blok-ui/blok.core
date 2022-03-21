package blok.framework;

import blok.core.Assert;

@:autoBuild(blok.framework.ComponentBuilder.build())
abstract class Component extends Element {
  var childElement:Null<Element> = null;
  var currentRevision:Int = 0;
  var lastRevision:Int = 0;

  abstract function render():Widget;
  abstract function updateWidget(incomingProps:Dynamic):Void;

  override function mount(parent:Element, ?slot:Slot) {
    super.mount(parent, slot);
    performBuild();
  }

  override function update(widget:Widget) {
    lifecycle = Valid;
    updateWidget(widget);
    if (shouldUpdate()) performBuild();
  }

  override function rebuildElement() {
    if (lifecycle != Invalid) return;
    assert(lifecycle != Building);
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

  function shouldUpdate():Bool {
    return currentRevision > lastRevision;
  }
}
