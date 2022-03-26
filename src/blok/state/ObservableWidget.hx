package blok.state;

import blok.core.Disposable;
import blok.core.UniqueId;
import blok.ui.Widget;
import blok.ui.ElementVisitor;
import blok.ui.Element;

class ObservableWidget<T> extends Widget {
  static final type = new UniqueId();

  public final observable:Observable<T>;
  public final build:(value:T)->Widget;
  
  public function new(observable, build, ?key) {
    super(key);
    this.build = build;
    this.observable = observable;
  }

  public function getWidgetType():UniqueId {
    return type;
  }

  public function createElement():Element {
    return new ObservableElement(this);
  }
}

class ObservableElement<T> extends Element {
  var link:Disposable = null;
  var value:Null<T> = null;
  var childElement:Null<Element> = null;

  public function visitChildren(visitor:ElementVisitor) {
    if (childElement != null) visitor.visit(childElement);
  }

  public function buildElement(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      track();
      performBuild();
    } else if (widget == previousWidget) {
      performBuild();
    } else {
      var obs:ObservableWidget<T> = cast widget;
      var oldObs:ObservableWidget<T> = cast previousWidget;

      if (obs.observable != oldObs.observable) {
        track();
      }

      performBuild();
    }
  }

  function track() {
    cleanupLink();

    var obs:ObservableWidget<T> = cast widget;
    var first = true;
    
    link = obs.observable.observe(value -> {
      this.value = value;
      if (!first) invalidateElement();
      first = false;
    });
  }

  inline function cleanupLink() {
    if (link != null) link.dispose();
    link = null;
  }

  function performBuild() {
    var obs:ObservableWidget<T> = cast widget;
    childElement = updateChild(childElement, obs.build(value), slot);
  }

  override function dispose() {
    super.dispose();
    cleanupLink();
  }
}