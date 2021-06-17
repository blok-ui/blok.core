package blok;

interface VNode {
  public final type:VNodeType;
  public final key:Null<Key>;
  public final props:Dynamic;
  public final children:Null<Array<VNode>>;
  public function createComponent(?parent:Component):Component;
  public function updateComponent(component:Component):Component;
}
