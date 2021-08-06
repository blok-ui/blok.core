package blok;

class ChildrenComponent extends Component {
  @prop var children:Array<VNode>;
  @prop var ref:Null<(text:String)->Void> = null;
  @prop var onupdate:Null<(comp:ChildrenComponent)->Void> = null;

  @effect
  public function handleRef() {
    if (ref != null) {
      ref(toString());
    }
    if (onupdate != null) {
      onupdate(this);
    }
  }

  @update
  public function setChildren(children) {
    return UpdateState({ children: children });
  }

  public function toString() {
    return Text.stringifyWidget(this); 
  }

  public function render() {
    return children;
  }
}
