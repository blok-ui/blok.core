package impl;

import blok.ui.*;

class RootWidget extends ConcreteWidget {
  static public final type:WidgetType = new WidgetType();

  var children:Array<VNode>;

  public function new(children) {
    this.children = children;
  }

  public function getWidgetType() {
    return type;
  }

  public function setChildren(newChildren:Array<VNode>) {
    __status = WidgetInvalid;
    children = newChildren;
  }

  public function toConcrete() {
    var text:Array<String> = [];
    for (child in getChildConcreteManagers()) text = text.concat(cast child.toConcrete());
    return text;
  }

  public function getFirstConcreteChild():Dynamic {
    return toConcrete()[0];
  }

  public function getLastConcreteChild():Dynamic {
    return toConcrete().pop();
  }

  public function __performUpdate(registerEffect:(effect:()->Void)->Void):Void {
    Differ.diffChildren(this, children, __platform, registerEffect);
  }

  public function addConcreteChild(child:Widget):Void {
    // noop
  }
  
  public function insertConcreteChildAt(pos:Int, child:Widget):Void {
    // noop
  }
  
  public function moveConcreteChildTo(pos:Int, child:Widget):Void {
    // noop
  }
  
  public function removeConcreteChild(child:Widget):Void {
    // noop
  }
  
}