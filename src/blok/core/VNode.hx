package blok.core;

enum VNode<RealNode> {
  VNative<Props:{}>(
    type:NodeType<Props, RealNode>,
    props:Props,
    ?ref:(node:RealNode)->Void, 
    ?key:Null<Key>, 
    ?children:Array<VNode<RealNode>>
  );
  VComponent<Props:{}>(
    type:ComponentType<RealNode, Props>,
    props:Props, 
    ?key:Null<Key>
  );
  VFragment(children:Array<VNode<RealNode>>, ?key:Null<Key>);
}
