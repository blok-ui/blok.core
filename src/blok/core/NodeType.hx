package blok.core;

typedef NodeType<Props:{}, RealNode> = {
  public function create(props:Props, context:Context<RealNode>):RealNode;
  public function update(
    node:RealNode, 
    previousProps:Props,
    props:Props,
    context:Context<RealNode>
  ):RealNode;
}
