package impl;

import blok.core.UniqueId;
import blok.ui.Element;
import blok.ui.Effects;
import blok.ui.RootWidget;
import blok.ui.ObjectWidget;
import blok.ui.RootElement;

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

class TestingRootElement extends RootElement {
  public function setChild(widget:ObjectWidget, ?next:Effect) {
    var prev:TestingRootWidget = cast this.widget;
    
    if (next != null) {
      if (effects == null) effects = new Effects();
      effects.register(next);
    }

    this.widget = new TestingRootWidget(
      prev.object,
      prev.platform,
      widget
    );

    invalidate();
  }

  public function toString() {
    return (getObject():TestingObject).toString();
  }
}

