package blok;

interface Plugin {
  public function prepareVNodes(component:Component, vnode:VNodeResult):VNodeResult;
  public function wasInitialized(component:Component):Void;
  public function wasRendered(component:Component):Void;
  public function willBeDisposed(component:Component):Void;
}
