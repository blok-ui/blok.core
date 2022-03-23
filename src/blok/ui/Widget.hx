package blok.ui;

import blok.core.UniqueId;

abstract class Widget {
  public final key:Null<Key>;

  public function new(key) {
    this.key = key;
  }

  abstract public function getWidgetType():UniqueId;
  abstract public function createElement():Element;

  public function canBeUpdated(newWidget:Widget):Bool {
    return getWidgetType() == newWidget.getWidgetType() && key == newWidget.key;
  }
}
