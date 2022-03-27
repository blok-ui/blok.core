package blok.state;

import blok.ui.HydrationCursor;
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

  public function performBuild(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      track();
      performBuildChild();
    } else if (widget == previousWidget) {
      performBuildChild();
    } else {
      var obs:ObservableWidget<T> = cast widget;
      var oldObs:ObservableWidget<T> = cast previousWidget;

      if (obs.observable != oldObs.observable) {
        track();
      }

      performBuildChild();
    }
  }

  function track() {
    cleanupLink();

    var obs:ObservableWidget<T> = cast widget;
    var first = true;
    
    link = obs.observable.observe(value -> {
      this.value = value;
      if (!first) invalidate();
      first = false;
    });
  }

  inline function cleanupLink() {
    if (link != null) link.dispose();
    link = null;
  }

  function performBuildChild() {
    var obs:ObservableWidget<T> = cast widget;
    childElement = updateChild(childElement, obs.build(value), slot);
  }

  override function dispose() {
    super.dispose();
    cleanupLink();
  }

  function performHydrate(cursor:HydrationCursor) {
    var obs:ObservableWidget<T> = cast widget;
    track();
    childElement = hydrateElementForWidget(cursor, obs.build(value), slot);
  }
}
