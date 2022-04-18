package blok.ui;

abstract class ProxyWidget extends Widget {
  public final child:Widget;

  public function new(child, ?key) {
    super(key);
    this.child = child;
  }

  public function createElement():Element {
    return new ProxyElement(this);
  }
}

class ProxyElement extends Element {
  var childElement:Null<Element> = null;

  function performHydrate(cursor:HydrationCursor) {
    childElement = hydrateElementForWidget(cursor, (cast widget:ProxyWidget).child, slot);
  }

  function performBuild(previousWidget:Null<Widget>) {
    childElement = updateChild(childElement, (cast widget:ProxyWidget).child, slot);
  }

  public function visitChildren(visitor:ElementVisitor) {
    if (childElement != null) visitor.visit(childElement);
  }
}
