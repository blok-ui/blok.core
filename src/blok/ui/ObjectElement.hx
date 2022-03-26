package blok.ui;

abstract class ObjectElement extends Element {
  var object:Null<Dynamic> = null;

  override function getObject():Dynamic {
    return object;
  }

  public function createObject():Dynamic {
    return platform.createObjectForWidget(cast widget);
  }

  public function updateObject(?oldWidget:Widget) {
    object = platform.updateObject(object, cast widget, cast oldWidget);
  }
}
