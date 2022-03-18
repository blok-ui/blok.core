package impl;

import blok.ui.*;

class ComponentApplicator implements Applicator {
  final component:Component;

  public function new(component) {
    this.component = component;
  }

  public function toConcrete():Array<Dynamic> {
    var text:Array<String> = [];
    for (child in component.getChildApplicators()) text = text.concat(cast child.toConcrete());
    return text;
  }

  public function getFirstConcreteChild():Dynamic {
    return toConcrete()[0];
  }

  public function getLastConcreteChild():Dynamic {
    return toConcrete().pop();
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

  public function dispose() {
    // noop
  }
}