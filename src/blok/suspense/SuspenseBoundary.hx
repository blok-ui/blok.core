package blok.suspense;

import blok.adaptor.Cursor;
import blok.boundary.Boundary;
import blok.core.Disposable;
import blok.debug.Debug;
import blok.ui.*;

using Lambda;
using blok.boundary.BoundaryTools;

enum SuspenseBoundaryStatus {
  Ok;
  Suspended(links:Array<SuspenseLink>);
}

typedef SuspenseBoundaryProps = {
  public final child:Child;

  /**
    Fallback to display while the component is suspended.
  **/
  public final fallback:()->Child;

  /**
    If this SuspenseBoundary has a SuspenseBoundary ancestor,
    suspend using that ancestor instead. Defaults to `false`.
  **/
  public final ?overridable:Bool;

  /**
    A callback the fires when *all* suspensions inside
    this Boundary are completed.
  **/
  public final ?onComplete:()->Void;

  /**
    Called when the Boundary is suspended. If more suspensions
    occur while the SuspenseBoundary is already suspended, this
    callback will *not* be called again.
  **/
  public final ?onSuspended:()->Void;
} 

class SuspenseBoundary extends View implements Boundary {
  public static function maybeFrom(context:View) {
    return context.findAncestorOfType(SuspenseBoundary);
  }

  public static final componentType:UniqueId = new UniqueId();
  
  public static function node(props:SuspenseBoundaryProps, ?key) {
    return new VComponent(componentType, props, SuspenseBoundary.new, key);
  }
  
  var child:Child;
  var fallback:()->Child;
  var hydrating:Bool = false;
  var suspenseStatus:SuspenseBoundaryStatus = Ok;
  var hiddenRoot:Null<View> = null;
  var hiddenSlot:Null<Slot> = null;
  var realChild:Null<View> = null;
  var currentChild:Null<View> = null;
  var onComplete:Null<()->Void>;
  var onSuspended:Null<()->Void>;
  var overridable:Bool;

  function new(node) {
    __node = node;
    var props:SuspenseBoundaryProps = __node.getProps();
    this.child = props.child;
    this.fallback = props.fallback;
    this.overridable = props.overridable ?? false;
    this.onComplete = props.onComplete;
    this.onSuspended = props.onSuspended;
  }

  function updateProps() {
    var props:SuspenseBoundaryProps = __node.getProps();
    var changed:Int = 0;

    if (child != props.child) {
      child = props.child;
      changed++;
    }

    if (fallback != props.fallback) {
      fallback = props.fallback;
      changed++;
    }

    if (onComplete != props.onComplete) {
      onComplete = props.onComplete;
      changed++;
    }

    if (onSuspended != props.onSuspended) {
      onSuspended = props.onSuspended;
      changed++;
    }

    var newSuspension = props.overridable ?? false;
    if (overridable != newSuspension) {
      overridable = newSuspension;
      changed++;
    }

    return changed > 0;
  }

  function setActiveChild() {
    var adaptor = getAdaptor();

    switch suspenseStatus {
      case Suspended(_) if (currentChild != realChild):
      case Suspended(_):
        realChild.updateSlot(hiddenSlot);
        currentChild = fallback().createComponent();
        currentChild.mount(adaptor, this, __slot);
      case Ok if (currentChild != realChild):
        currentChild?.dispose();
        currentChild = realChild;
        realChild.updateSlot(__slot);
      case Ok:
        realChild.updateSlot(__slot);
    }
  }

  function setupHiddenRoot() {
    var adaptor = getAdaptor();

    hiddenRoot = Root.node({
      target: adaptor.createContainerNode({}),
      child: () -> Placeholder.node()
    }).createComponent();
    
    hiddenRoot.mount(adaptor, null, null);
    hiddenSlot = createSlot(1, hiddenRoot.findChildOfType(Placeholder).unwrap());
  }

  public function handle(component:View, object:Any) {
    if (!(object is SuspenseException)) {
      this.tryToHandleWithBoundary(object);
      return;
    }

    if (hydrating) error('SuspenseBoundary suspended during hydration.');

    if (overridable) switch SuspenseBoundary.maybeFrom(this) {
      case Some(boundary):
        boundary.handle(component, object);
        return;
      case None:
    }

    var suspense:SuspenseException = object;
    var link:Null<SuspenseLink> = null;

    suspenseStatus = switch suspenseStatus {
      case Suspended(links):
        link = links.find(link -> link.component == component);
        if (link == null) {
          link = new SuspenseLink(component, this);
          component.addDisposable(link);
          links.push(link);
        }
        Suspended(links);
      case Ok:
        triggerOnSuspended();
        link = new SuspenseLink(component, this);
        component.addDisposable(link);
        Suspended([ link ]);
    }

    setActiveChild();
    assert(link != null);

    link.set(suspense.task.handle(result -> switch result {
      case Ok(_):
        switch __status {
          case Disposing | Disposed: return;
          default:
        }
        resolveAndRemoveSuspenseLink(link);
      case Error(error):
        switch __status {
          case Disposing | Disposed: return;
          default:
        }
        this.tryToHandleWithBoundary(error);
    }));
  }

  function resolveAndRemoveSuspenseLink(link:SuspenseLink) {
    suspenseStatus = switch suspenseStatus {
      case Suspended(links):
        links.remove(link);
        link.component.removeDisposable(link);
        if (links.length == 0) {
          Ok;
        } else {
          Suspended(links);
        }
      case Ok: 
        Ok;
    }

    if (suspenseStatus == Ok) {
      setActiveChild();
      getAdaptor().schedule(triggerOnComplete);
    }
  }

  function triggerOnSuspended() {
    if (onSuspended != null) onSuspended();
    switch SuspenseBoundaryContext.maybeFrom(this) {
      case Some(context): context.add(this);
      case None:
    }
  }

  function triggerOnComplete() {
    if (onComplete != null) onComplete();
    switch SuspenseBoundaryContext.maybeFrom(this) {
      case Some(context): context.remove(this);
      case None:
    }
  }

  function __initialize() {
    setupHiddenRoot();

    currentChild = realChild = child.createComponent();
    realChild.mount(getAdaptor(), this, __slot);

    setActiveChild();
  }

  function __hydrate(cursor:Cursor) {
    hydrating = true;
    setupHiddenRoot();

    currentChild = realChild = child.createComponent();
    realChild.hydrate(cursor, getAdaptor(), this, __slot);
    hydrating = false;
  }

  function __update() {
    if (!updateProps()) return;
    realChild.update(child);
    setActiveChild();
  }

  function __validate() {
    setActiveChild();
  }

  function __dispose() {
    switch SuspenseBoundaryContext.maybeFrom(this) {
      case Some(context): context.remove(this);
      case None:
    }
    hiddenRoot?.dispose();
    hiddenRoot = null;
    hiddenSlot = null;
    realChild.dispose();
    if (currentChild != realChild) currentChild?.dispose();
    currentChild = null;
  }

  function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
    currentChild?.updateSlot(newSlot);
  }

  public function getPrimitive():Dynamic {
    assert(currentChild != null);
    return currentChild.getPrimitive();
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:View) -> Bool) {
    if (currentChild != null) visitor(currentChild);
  }
}

@:access(blok.suspense)
class SuspenseLink implements Disposable {
  public final component:View;
  final suspense:SuspenseBoundary;
  
  var link:Null<Cancellable> = null;

  public function new(component, suspense) {
    this.component = component;
    this.suspense = suspense;
  }

  public function set(newLink:Cancellable) {
    link?.cancel();
    link = newLink;
  }

  public function dispose() {
    link?.cancel();
    link = null;
    suspense.resolveAndRemoveSuspenseLink(this);
  }
}
