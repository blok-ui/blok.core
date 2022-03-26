package blok.ui;

import blok.core.Debug;

class RootElement extends ObjectElement {
  var child:Null<Element> = null;

  public function new(root:RootWidget) {
    super(root);
    platform = root.platform;
    parent = null;
  }

  public function bootstrap() {
    mount(null);
  }

  override function getObject():Dynamic {
    return (cast widget:RootWidget).resolveRootObject();
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    Debug.assert(parent == null, 'Root elements should not have a parent');
    status = Active;
    lifecycle = Building;
    buildElement(null);
    lifecycle = Valid;
  }

  function buildElement(previousWidget:Widget) {
    performBuild();
  }

  function performBuild() {
    child = updateChild(child, (cast widget:RootWidget).child, slot);
  }
  
  function visitChildren(visitor:ElementVisitor) {
    if (child != null) visitor.visit(child);
  }
}
