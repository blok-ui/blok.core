package blok.framework;

abstract class RootElement extends Element {
  var child:Null<Element> = null;

  public function new(root:RootWidget) {
    super(root);
    platform = root.platform;
    parent = null;
  }

  abstract function resolveRootObject():Dynamic;

  override function getObject():Dynamic {
    return resolveRootObject();
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    var root:RootWidget = cast widget;
    
    status = Active;
    child = createElementForWidget(root.child);
  }
  
  function visitChildren(visitor:ElementVisitor) {
    if (child != null) visitor.visit(child);
  }
}
