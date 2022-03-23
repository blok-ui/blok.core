package blok.ui;

abstract class ObjectWidget extends Widget {
  abstract public function getChildren():Array<Widget>;
  abstract public function createObject():Dynamic;
  abstract public function updateObject(object:Dynamic, ?previousWidget:Widget):Dynamic;
}
