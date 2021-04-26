package blok;

class ContextConsumer extends Component {
  @prop var build:(context:Context)->VNode;
  var context:Null<Context> = null;

  @before
  public function findContext() {
    context = switch findInheritedComponentOfType(Provider) {
      case None: new Context();
      case Some(provider): provider.getContext(); 
    }
  }

  public function getContext() {
    return context;
  }

  public function render() {
    return build(context);
  }
}
