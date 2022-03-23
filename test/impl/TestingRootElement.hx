package impl;

import blok.ui.Effects;
import blok.ui.RootElement;
import blok.ui.ObjectWidget;

class TestingRootElement extends RootElement {
  var effects:Effects = null;

  function resolveRootObject():Dynamic {
    return (cast widget:TestingRootWidget).object;
  }

  public function setChild(widget:ObjectWidget, ?next:Effect) {
    var prev:TestingRootWidget = cast this.widget;
    
    // @todo: The way I'm handling effects is a mess.
    if (effects == null) effects = new Effects();
    if (next != null) effects.register(next);

    this.widget = new TestingRootWidget(
      prev.object,
      prev.platform,
      widget
    );

    invalidateElement();
  }

  override function performBuild() {
    super.performBuild();
    if (effects != null) {
      var e = effects;
      effects = null;
      platform.scheduleEffects(effects -> effects.register(e.dispatch));
    }
  }

  public function toString() {
    return (getObject():TestingObject).toString();
  }
}
