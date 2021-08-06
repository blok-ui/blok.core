package blok;

class VFragment implements VNode {
  public final type:WidgetType = FragmentWidget.type;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>> = [];

  public function new(text:String, ?key) {
    props = text; 
    this.key = key;
  }

  public function createWidget(?parent:Widget, platform, registerEffect):Widget {
    var fragment = new FragmentWidget(children);
    fragment.initializeWidget(parent, platform, key);
    fragment.performUpdate(registerEffect);
    return fragment;
  }

  public function updateWidget(widget:Widget, registerEffect):Widget {
    var fragment:FragmentWidget = cast widget;
    fragment.setChildren(children);
    fragment.performUpdate(registerEffect);
    return fragment;
  }
}
