package blok.ui;

interface VNode {
  public final type:WidgetType;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>>;
  public function createWidget(?parent:Widget, platform:Platform, registerEffect:(effect:()->Void)->Void):Widget;
  public function updateWidget(widget:Widget, registerEffect:(effect:()->Void)->Void):Widget;
}
