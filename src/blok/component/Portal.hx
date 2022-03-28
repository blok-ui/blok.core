package blok.component;

import blok.core.UniqueId;
import blok.ui.*;

abstract class Portal extends ObjectWidget {
  static final type = new UniqueId();  

  public final child:Widget;

  public function new(child, ?key) {
    super(key);
    this.child = child;
  }

  abstract public function getTargetObject():Dynamic;

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return new PortalElement(this);
  }

  public function getChildren():Array<Widget> {
    return [ child ];
  }

  public function createObject():Dynamic {
    return getTargetObject();
  }

  public function updateObject(object:Dynamic, ?previousWidget:Widget):Dynamic {
    return object;
  }
}

class PortalElement extends ObjectElement {
  var child:Element = null;

  function performHydrate(cursor:HydrationCursor) {
    // noop
  }

  function performBuild(previousWidget:Null<Widget>) {
    var portal:Portal = cast widget;
    
    if (previousWidget == null) {
      object = portal.getTargetObject();
    }
    
    child = updateChild(child, portal.child, createSlotForChild(0, null));
  }

  public function visitChildren(visitor:ElementVisitor) {
    if (child != null) visitor.visit(child);
  }

  override function dispose() {
    super.dispose();
    object = null;
  }
}
