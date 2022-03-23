package impl;

import blok.core.UniqueId;
import blok.ui.Widget;
import blok.ui.ObjectWidget;

class TextWidget extends ObjectWidget {
  public static final type = new UniqueId();

  public final content:String;
  public final ref:Null<(object:TestingObject)->Void>;

  public function new(content, ?key, ?ref) {
    super(key);
    this.content = content;
    this.ref = ref;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement() {
    return new TextElement(this);
  }

  public function getChildren():Array<Widget> {
    return [];
  }

  public function createObject():Dynamic {
    return new TestingObject(content);
  }

  public function updateObject(object:Dynamic, ?previousWidget:Widget):Dynamic {
    (object:TestingObject).content = content;
    return object;
  }
}
