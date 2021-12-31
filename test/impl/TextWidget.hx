package impl;

import blok.ui.*;

class TextWidget extends ConcreteWidget {
  static public final type:WidgetType = new WidgetType(); 

  static public inline function node(text, ?key, ?ref) {
    return new VText(text, key, ref);
  }
  
  public function requestResortWidgets():Void {
    // noop
  }
  
  var internalTextContent:String;
  var ref:Null<(content:String)->Void>;

  public function new(text:String, ?ref) {
    internalTextContent = text;
    this.ref = ref;
  }

  public function __performUpdate(registerEffect:(effect:()->Void)->Void) {
    if (ref != null) registerEffect(() -> ref(internalTextContent));
  }

  public function shouldUpdate(text:String) {
    return internalTextContent != text;
  }

  public function setText(text:String) {
    internalTextContent = text;
  }

  public function getWidgetType() {
    return type;
  }

  public function toConcrete() {
    return [ internalTextContent ];
  }

  public function getFirstConcreteChild():Dynamic {
    return internalTextContent;
  }

  public function getLastConcreteChild():Dynamic {
    return internalTextContent;
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
