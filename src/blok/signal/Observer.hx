package blok.signal;

import blok.core.Disposable;

@:forward(dispose)
abstract Observer(ReactiveNode) to Disposable {
  public static function untrack(effect:()->Void) {
    Runtime.current().withCurrentConsumer(null, effect);
  }

  public inline static function track(effect:()->Void):Disposable {
    return new Observer(effect);
  }

  public function new(effect:()->Void) {
    this = new ReactiveNode(
      Runtime.current(),
      node -> node.useAsCurrentConsumer(effect),
      true
    );
    this.useAsCurrentConsumer(effect);
  }  
}
