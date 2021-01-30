package blok;

class NotifyingSubscriber<T:Service> extends Component {
  @prop(onChange = cleanupLink()) var target:Notifies<T>;
  @prop var build:(value:T)->VNode;
  @prop var teardown:(service:T)->Void = null;
  var link:Disposable;
  var service:T;

  @init
  @effect
  function subscribe() {
    if (link != null) return;

    var first = true;
    link = target.notifier().subscribe(service -> {
      if (this.service != service) {
        if (this.service != null) maybeTeardown();
        this.service = service;
      }
      if (!first) {
        invalidateComponent();
      } else {
        first = false;
      }
    });
  }

  @dispose
  function cleanupLink() {
    if (link != null) link.dispose();
    link = null;
  }
  
  @dispose
  public function maybeTeardown() {
    if (teardown != null && service != null) teardown(service);
    service = null;
  }

  override function render(context:Context) {
    return build(service);
  }
}