package blok;

interface VNode {
  public final type:VNodeType;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>>;
  public function createComponent(engine:Engine, ?parent:Component):Component;
  public function updateComponent(engine:Engine, component:Component):Component;
}
