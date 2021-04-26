package blok;

import blok.Observable;

class ObservableSubscriber<T> extends Component {
  public static function observe(target, build, ?teardown) {
    return ObservableSubscriber.node({
      target: target,
      build: build,
      teardown: teardown
    });
  }

  @prop(onChange = cleanupLink()) var target:ObservableTarget<T>;
  @prop var build:(value:T)->VNode;
  @prop var teardown:(value:T)->Void = null;
  var link:Disposable;
  var value:T;

  @init
  @effect
  function track() {
    if (link != null) return;
    var first = true;
    link = target.observe(value -> {
      if (this.value != value) {
        if (this.value != null) maybeTeardown();
        this.value = value;
      }
      if (!first) updateComponent();
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

  public function render() {
    return build(value);
  }
}
