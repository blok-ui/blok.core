package impl;

import blok.ui.Effects;
import blok.core.UniqueId;
import blok.ui.Widget;
import blok.ui.ObjectWidget;
import blok.ui.Element;
import blok.ui.Slot;
import blok.ui.ObjectWithoutChildrenElement;

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

class TextElement extends ObjectWithoutChildrenElement {
  override function registerEffects(effects:Effects) {
    var text:TextWidget = cast widget;
    if (text.ref != null) {
      effects.register(() -> text.ref(object));
    }
  }
}
