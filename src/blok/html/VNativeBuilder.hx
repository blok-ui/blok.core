package blok.html;

import blok.ui.*;
import blok.diffing.Key;

// @todo: This seems like a pretty wasteful implementation.

@:forward
@:forward.new
abstract VNativeBuilder<Props:{}>(VNativeBuilderObject<Props>) from VNativeBuilderObject<Props> {
  @:to public function into():VNode {
    return new VNative(this.type, this.tag, this.props, this.children, this.key);
  }

  @:to public inline function toChild():Child {
    return into();
  }
}

class VNativeBuilderObject<Props:{}> {
  public final type:UniqueId;
  public final tag:String;
  public var key:Null<Key>;
  public var props:Props;
  public var children:Null<Array<Child>>;

  public function new(type, tag, props, ?children, ?key) {
    this.type = type;
    this.tag = tag;
    this.props = props;
    this.key = key;
    this.children = children;
  }

  public function withKey(key:Key):VNativeBuilder<Props> {
    this.key = key;
    return this;
  }

  public function wrap(...children:Child):VNativeBuilder<Props> {
    if (this.children == null) {
      this.children = children.toArray();
      return this;
    }
    this.children = this.children.concat(children);
    return this;
  }

  public inline function track(render:(context:Component)->Child) {
    return wrap(Scope.wrap(render));
  }
}
