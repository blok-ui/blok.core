package blok.context;

import blok.ui.*;

class Provider<T:Providable> extends Component {
  public static function compose(contexts:Array<()->Providable>, child:(context:ComponentBase)->Child) {
    var contextFactory = contexts.shift();
    var component:VNode = Provider.provide(contextFactory, _ -> Scope.wrap(child));
    while (contexts.length > 0) {
      var wrapped = component;
      contextFactory = contexts.shift();
      component = Provider.provide(contextFactory, _ -> wrapped);
    }
    return component;
  }

  public inline static function provide<T:Providable>(create:()->T, child:(value:T)->Child) {
    return node({
      create: create,
      child: child
    });
  }

  @:attribute final create:()->T;
  @:children @:attribute final child:(value:T)->Child;

  var context:Null<T> = null;

  function setup() {
    addDisposable(() -> {
      context?.dispose();
      context = null;
    });
  }

  public function match(contextId:Int):Bool {
    return context?.getContextId() == contextId;
  }

  public function getContext():Maybe<T> {
    return context != null ? Some(context) : None;
  }

  function render() {
    var newContext = create();
    if (newContext != context) {
      context?.dispose();
      context = newContext;
    }
    return child(context);
  }
}
