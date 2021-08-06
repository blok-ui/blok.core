package html;

import blok.Widget;
import blok.WidgetType;
import blok.VNode;
import blok.Key;
import blok.Platform;

class Text implements VNode {
  public final type:WidgetType = TextWidget.type;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>> = null;

  public function new(text:String, ?key) {
    this.key = key;
    this.props = text;
  }

  public function createWidget(?parent:Widget, platform:Platform, registerEffect:(effect:()->Void)->Void):Widget {
    var widget = new TextWidget(props);
    widget.initializeWidget(parent, platform, key);
    widget.performUpdate(registerEffect);
    return widget;
  }

  public function updateWidget(widget:Widget, registerEffect:(effect:()->Void)->Void):Widget {
    var text:TextWidget = cast widget;
    text.update(props);
    text.performUpdate(registerEffect);
    return widget;
  }
}
