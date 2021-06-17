package blok;

class TextComponent extends Component {
  @prop public var content:String;
  @prop var ref:Null<(text:String)->Void> = null;
  
  @effect
  function handleRef() {
    if (ref != null) ref(content);
  }
  
  public function render() {
    return null;
  }

  override function __ensureVNode(vn) {
    return vn;
  }
}
