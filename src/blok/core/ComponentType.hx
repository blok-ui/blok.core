package blok.core;

import blok.core.Component;

typedef ComponentType<RealNode, Props> = {
  public function create(
    props:Props,
    parent:Null<Component<RealNode>>,
    context:Context<RealNode>
  ):Component<RealNode>;
  public function update(
    component:Component<RealNode>,
    props:Props,
    parent:Null<Component<RealNode>>,
    context:Context<RealNode>
  ):Component<RealNode>;
}
