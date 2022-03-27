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

  override function createObject():Dynamic {
    return (cast widget:RootWidget).resolveRootObject(); 
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    Debug.assert(parent == null, 'Root elements should not have a parent');
    status = Active;
    lifecycle = Building;
    performBuild(null);
    lifecycle = Valid;
  }

  function performBuild(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      object = createObject();
    } else {
      if (previousWidget != widget) updateObject(previousWidget);
    }
    performBuildChild();
  }

  function performBuildChild() {
    child = updateChild(child, (cast widget:RootWidget).child, slot);
  }
  
  function visitChildren(visitor:ElementVisitor) {
    if (child != null) visitor.visit(child);
  }
}
