package blok;

enum VNode {
  None;
  VComponent<T:Component, Props:{}>(type:ComponentType<T, Props>, properties:Props, ?key:Key);
  VFragment(nodes:Array<VNode>);
}
