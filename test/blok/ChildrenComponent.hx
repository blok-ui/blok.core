package blok;

class ChildrenComponent extends Component {
  @prop var children:Array<VNode>;
  @prop var ref:Null<(text:String)->Void> = null;

  @effect
  public function handleRef() {
    if (ref != null) {
      ref(toString());
    }
  }

  public function toString() {
    return Text.getTextFromComponent(this); 
  }

  public function render():VNode {
    return new VFragment(children);
  }
}
