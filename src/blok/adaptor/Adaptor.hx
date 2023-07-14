package blok.adaptor;

import blok.ui.*;

interface Adaptor {
  public function schedule(effect:()->Void):Void;
  public function createNode(name:String, attrs:{}):Dynamic;
  public function createPlaceholderNode():Dynamic;
  public function createTextNode(text:String):Dynamic;
  public function createContainerNode(attrs:{}):Dynamic;
  public function createCursor(object:Dynamic):Cursor;
  public function updateTextNode(object:Dynamic, value:String):Void;
  public function updateNodeAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Dynamic, ?isHydrating:Bool):Void;
  public function insertNode(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic):Void;
  public function moveNode(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic):Void;
  public function removeNode(object:Dynamic, slot:Null<Slot>):Void;
}
