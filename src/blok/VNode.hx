package blok;

enum VNode {
  VNone;
  VComponent<T:Component, Props:{}>(type:ComponentType<T, Props>, properties:Props, ?key:Key);
  VFragment(nodes:Array<VNode>);
}
