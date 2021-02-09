package blok.core;

interface Engine<RealNode> {
  public function traverseSiblings(first:RealNode):Cursor<RealNode>;
  public function traverseChildren(parent:RealNode):Cursor<RealNode>;
  public function getRenderResult(node:RealNode):Null<RenderResult<RealNode>>;
  public function setRenderResult(node:RealNode, rendered:Null<RenderResult<RealNode>>):Void;
  public function createPlaceholder(component:Component<RealNode>):VNode<RealNode>;
}
