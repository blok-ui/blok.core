package blok.core;

enum RNode<RealNode> {
  RNative<Props:{}>(node:RealNode, props:Props);
  RComponent<Props:{}>(component:Component<RealNode>);
}
