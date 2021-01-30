package blok;

class ChangeSubscriber<T> extends Component {
  @prop(onChange = cleanupLink()) var target:Changes<T>;
  @prop var build:(value:T)->VNode;
  @prop var teardown:(value:T)->Void = null;
  var link:Disposable;
  var value:T;

  @init
  @effect
  function track() {
    if (link != null) return;
    value = target.getCurrentValue();
    link = target.getChangeSignal().add(value -> {
      if (this.value != value) {
        if (this.value != null) maybeTeardown();
        this.value = value;
      }
      invalidateComponent();
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

  override function render(context:Context) {
    return build(value);
  }
}