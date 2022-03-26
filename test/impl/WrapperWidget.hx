package impl;

import blok.core.UniqueId;
import blok.ui.Widget;
import blok.ui.Element;
import blok.ui.ObjectWidget;
import blok.ui.ObjectWithChildrenElement;

class WrapperWidget extends ObjectWidget {
  public static final type = new UniqueId();

  final children:Array<Widget>;
  
  public function new(children, ?key) {
    super(key);
    this.children = children;
  }

  public function getChildren():Array<Widget> {
    return children;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return new ObjectWithChildrenElement(this);
  }

  public function createObject():Dynamic {
    return new TestingObject('');
  }

  public function updateObject(object:Dynamic, ?previousWidget:Widget):Dynamic {
    return object;
  }
}
