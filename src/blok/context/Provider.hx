package blok.context;

import blok.ui.*;

class Provider<T:Context> extends Component {
  @:constant final create:()->T;
  @:constant final child:(value:T)->Child;

  var context:Null<T> = null;

  function setup() {
    addDisposable(() -> {
      context?.dispose();
      context = null;
    });
  }

  public function match(contextId:Int):Bool {
    return context?.__getContextId() == contextId;
  }

  public function getContext():Maybe<T> {
    return context != null ? Some(context) : None;
  }

  function render() {
    context?.dispose();
    context = create();
    return child(context);
  }
}
