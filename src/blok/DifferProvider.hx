package blok;

class DifferProvider extends Component {
  @prop var differ:Differ;
  @prop var child:VNode;

  public function render() {
    return child;
  }

  override function __getDiffer():Differ {
    return differ;
  }
}
