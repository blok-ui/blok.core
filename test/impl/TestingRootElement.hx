package impl;

import blok.ui.Effects;
import blok.ui.RootElement;
import blok.ui.ObjectWidget;

// Note: most platforms should be able to just implement
// the RootWidget and ignore needing a custom RootElement.
//
// @todo: It would probably be a good idea to integrate Effects
// into the Element lifecycle better.
class TestingRootElement extends RootElement {
  var effects:Effects = null;

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

    invalidate();
  }

  override function performBuildChild() {
    super.performBuildChild();
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
