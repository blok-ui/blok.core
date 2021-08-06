package blok;

import blok.exception.NoProviderException;

class ContextUser extends Component {
  @prop var build:(context:Context)->VNode;
  @prop var fallback:Null<Context> = null;
  var context:Null<Context> = null;

  @before
  public function findContext() {
    context = switch findParentOfType(Provider) {
      case None if (fallback != null):
        fallback;
      case None:
        throw new NoProviderException(this); 
      case Some(provider): 
        provider.getContext(); 
    }
  }

  public function getContext() {
    return context;
  }

  public function render() {
    return build(context);
  }
}
