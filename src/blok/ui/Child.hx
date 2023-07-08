package blok.ui;

import blok.signal.Computation;
import blok.signal.Signal;

@:forward
abstract Child(VNode) from Text from VNode to VNode {
  @:from
  public inline static function ofComputationString(content:Computation<String>):Child {
    return Text.ofSignal(content);
  }

  @:from
  public inline static function ofReadonlySignalString(content:ReadonlySignal<String>):Child {
    return Text.ofSignal(content);
  }

  @:from
  public inline static function ofSignalString(content:Signal<String>):Child {
    return Text.ofSignal(content);
  }

  @:from
  public inline static function ofString(content:String):Child {
    return (content:Text);
  }

  @:from
  public inline static function ofInt(content:Int):Child {
    return (content:Text);
  }

  @:from
  public inline static function ofFloat(content:Float):Child {
    return (content:Text);
  }
}
