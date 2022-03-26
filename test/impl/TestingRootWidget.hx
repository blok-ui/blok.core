package impl;

import blok.core.UniqueId;
import blok.ui.Element;
import blok.ui.RootWidget;

class TestingRootWidget extends RootWidget {
  public static final type:UniqueId = new UniqueId();

  public final object:TestingObject;

  public function new(object, platform, child) {
    super(platform, child);
    this.object = object;
  }
  
  public function getWidgetType():UniqueId {
    return type;
  }

  override function createElement():Element {
    return new TestingRootElement(this);
  }

  public function resolveRootObject():Dynamic {
    return object;
  }
}
