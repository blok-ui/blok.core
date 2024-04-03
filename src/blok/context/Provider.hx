package blok.context;

import blok.context.Providable;
import blok.ui.*;

class Provider<T:Providable> extends Component {
  public static function compose(contexts:Array<()->Providable>) {
    return new VProvider(contexts);
  }

  public inline static function provide(create:()->Providable) {
    return new VProvider([ create ]);
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

abstract VProvider({
  public final contexts:Array<()->Providable>;
  public var child:Null<(context:View)->Child>;
}) {
  public inline function new(contexts) {
    this = {
      contexts: contexts,
      child: null
    };
  }

  public inline function provide(value) {
    this.contexts.push(value);
    return abstract;
  }

  public inline function child(child:(context:View)->Child) {
    this.child = child;
    return abstract;
  }

  @:to
  public function node():Child {
    var contexts = this.contexts.copy();
    var child = this.child;
    var contextFactory = contexts.shift();
    var component:VNode = Provider.node({
      create: contextFactory,
      child: _ -> Scope.wrap(child)
    });

    while (contexts.length > 0) {
      var wrapped = component;
      contextFactory = contexts.shift();
      component = Provider.node({
        create: contextFactory,
        child: _ -> wrapped
      });
    }

    return component;
  }
}
