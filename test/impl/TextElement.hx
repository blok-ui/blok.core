package impl;

import blok.ui.Widget;
import blok.ui.Element;
import blok.ui.Slot;
import blok.ui.SingleObjectElement;

class TextElement extends SingleObjectElement {
  override function mount(parent:Null<Element>, ?slot:Slot) {
    super.mount(parent, slot);
    registerRef();
  }

  override function update(widget:Widget) {
    super.update(widget);
    registerRef();
  }

  inline function registerRef() {
    var text:TextWidget = cast widget;
    if (text.ref != null) platform.scheduleEffects(effects -> {
      effects.register(() -> text.ref(object));
    });
  }
}
