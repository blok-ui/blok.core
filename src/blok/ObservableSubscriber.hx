package blok;

import blok.Observable;

final class ObservableSubscriber<T> extends Component {
  public inline static function observe(target, build, ?teardown) {
    return ObservableSubscriber.node({
      target: target,
      build: build,
      teardown: teardown
    });
  }

  @prop(onChange = cleanupLink()) var target:ObservableTarget<T>;
  @prop var build:(value:Null<T>)->VNode;
  @prop var teardown:Null<(value:T)->Void> = null;
  @prop var onDispose:Null<()->Void> = null;
  var link:Null<Disposable> = null;
  var value:Null<T> = null;

  @before
  function track() {
    if (link != null) return;
    var first = true;
    link = target.observe(value -> {
      if (this.value != value) {
        if (this.value != null) maybeTeardown();
        this.value = value;
      }
      if (!first) invalidateWidget();
      first = false;
    });
  }

  @dispose
  function cleanupLink() {
    if (link != null) link.dispose();
    link = null;
  }
  
  @dispose
  public function maybeTeardown() {
    if (teardown != null && value != null) teardown(value);
    value = null;
  }

  @dispose
  function maybeRunDisposeHook() {
    if (onDispose != null) onDispose();
  }

  function render() {
    return build(value);
  }
}
