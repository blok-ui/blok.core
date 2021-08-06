package blok;

class VText implements VNode {
  public final type:WidgetType = TextWidget.type;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>> = [];
  final ref:Null<(content:String)->Void>;

  public function new(text:String, ?key, ?ref) {
    props = text; 
    this.key = key;
    this.ref = ref;
  }

  public function createWidget(?parent:Widget, platform, registerEffect):Widget {
    var text = new TextWidget(props, ref);
    text.initializeWidget(parent, platform, key);
    text.performUpdate(registerEffect);
    return text;
  }

  public function updateWidget(widget:Widget, registerEffect):Widget {
    var text:TextWidget = cast widget;
    if (text.shouldUpdate(props)) {
      text.setText(props);
      text.performUpdate(registerEffect);
    }
    return text;
  }
}
