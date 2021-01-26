package blok.core;

interface Component<RealNode> extends Disposable {
  public function getSideEffects():Array<()->Void>;
  public function getLastRenderResult():RenderResult<RealNode>;
  public function render(context:Context<RealNode>):VNode<RealNode>;
  public function invalidateComponent():Void;
  public function componentIsInvalid():Bool;
  public function componentIsAlive():Bool;
  private function executeRender(asRoot:Bool = false):Void;
  private function enqueuePendingChild(child:Component<RealNode>):Void;
  private function dequeuePendingChildren():Void;
}
