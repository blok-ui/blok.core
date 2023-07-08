package blok.ui;

import blok.diffing.Key;

class VNative implements VNode {
  public final type:UniqueId;
  public final key:Null<Key>;
  public final tag:String;
  public final props:{};
  public final children:Null<Children>;

  public function new(type, tag, props, ?children, ?key) {
    this.type = type;
    this.tag = tag;
    this.props = props;
    this.children = children;
    this.key = key;
  }

  public function getProps<T:{}>():T {
    return cast props;
  }

  public function createComponent():Component {
    return new NativeComponent(this);
  }
}
