package blok.ui;

import blok.core.Debug;

abstract class RootElement extends Element {
  var child:Null<Element> = null;

  public function new(root:RootWidget) {
    super(root);
    platform = root.platform;
    parent = null;
  }

  public function bootstrap() {
    mount(null);
  }

  abstract function resolveRootObject():Dynamic;

  override function getObject():Dynamic {
    return resolveRootObject();
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    Debug.assert(parent == null, 'Root elements should not have a parent');
    status = Active;
    lifecycle = Valid;
    performBuild();
  }

  override function update(widget:Widget) {
    this.widget = widget;
    performBuild();
  }

  function rebuildElement() {
    if (lifecycle != Invalid) return;
    performBuild();
  }

  function performBuild() {
    Debug.assert(lifecycle != Building);
    lifecycle = Building;
    child = updateChild(child, (cast widget:RootWidget).child, slot);
    lifecycle = Valid;
  }
  
  function visitChildren(visitor:ElementVisitor) {
    if (child != null) visitor.visit(child);
  }
}
