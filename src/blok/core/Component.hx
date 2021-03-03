package blok.core;

interface Component<RealNode> extends Disposable {
  public function getSideEffects():Array<()->Void>;
  public function getRenderResult():RenderResult<RealNode>;
  public function render(context:Context<RealNode>):VNode<RealNode>;
  public function invalidateComponent():Void;
  public function componentShouldUpdate():Bool;
  public function componentIsInvalid():Bool;
  public function componentIsAlive():Bool;
  // public function componentCaught(e:haxe.Exception):Void;
  private function executeRender(asRoot:Bool = false):Void;
  private function enqueuePendingChild(child:Component<RealNode>):Void;
  private function dequeuePendingChildren():Void;
}
