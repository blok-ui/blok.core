package blok.suspense;

import blok.diffing.Differ.updateChild;
import blok.adaptor.Cursor;
import blok.boundary.Boundary;
import blok.debug.Debug;
import blok.ui.*;

using blok.boundary.BoundaryTools;

enum SuspenseBoundaryStatus {
  Ok;
  Suspended(remaining:Int);
}

typedef SuspenseBoundaryProps = {
  public final child:Child;
  public final fallback:()->Child;

  /**
    If this SuspenseBoundary has a SuspenseBoundary ancestor,
    suspend using that ancestor instead. Defaults to `false`.
  **/
  public final ?overridable:Bool;
  public final ?onComplete:()->Void;
  public final ?onSuspended:()->Void;
} 

// @todo: I'm not convinced this thing actually always works.
class SuspenseBoundary extends ComponentBase implements Boundary {
  public static function maybeFrom(context:ComponentBase) {
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
  var hiddenRoot:Null<ComponentBase> = null;
  var hiddenSlot:Null<Slot> = null;
  var realChild:Null<ComponentBase> = null;
  var currentChild:Null<ComponentBase> = null;
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
    switch suspenseStatus {
      case Suspended(_) if (currentChild != realChild):
      case Suspended(_):
        realChild.updateSlot(hiddenSlot);
        currentChild = fallback().createComponent();
        currentChild.mount(this, __slot);
      case Ok if (currentChild != realChild):
        currentChild?.dispose();
        currentChild = realChild;
        realChild.updateSlot(__slot);
      case Ok:
        realChild.updateSlot(__slot);
    }
  }

  function setupHiddenRoot() {
    hiddenRoot = RootComponent.node({
      target: getAdaptor().createContainerNode({}),
      child: () -> Placeholder.node(),
      adaptor: getAdaptor()
    }).createComponent();
    
    hiddenRoot.mount(null, null);
    hiddenSlot = createSlot(1, hiddenRoot.findChildOfType(Placeholder).unwrap());
  }

  public function handle(component:ComponentBase, object:Any) {
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

    suspenseStatus = switch suspenseStatus {
      case Suspended(remaining):
        Suspended(remaining + 1);
      case Ok:
        triggerOnSuspended();
        Suspended(1);
    }

    setActiveChild();
    
    // @todo: We need to track the component this Task comes from:
    // if the component cancels this task we shouldn't be suspended
    // on it anymore. Not sure about the best way to do that.
    //
    // Also we should keep track of our links and cancel them as 
    // needed.
    suspense.task.handle(result -> switch result {
      case Ok(_):
        switch __status {
          case Disposing | Disposed: return;
          default:
        }
        suspenseStatus = switch suspenseStatus {
          case Suspended(remaining):
            remaining -= 1;
            if (remaining == 0) {
              Ok;
            } else {
              Suspended(remaining);
            }
          case Ok: 
            Ok;
        }
        if (suspenseStatus == Ok) {
          setActiveChild();
          getAdaptor().schedule(triggerOnComplete);
        }
      case Error(error):
        switch __status {
          case Disposing | Disposed: return;
          default:
        }
        this.tryToHandleWithBoundary(error);
    });
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
    realChild.mount(this, __slot);

    setActiveChild();
  }

  function __hydrate(cursor:Cursor) {
    hydrating = true;
    setupHiddenRoot();

    currentChild = realChild = child.createComponent();
    realChild.hydrate(cursor, this, __slot);
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

  public function getRealNode():Dynamic {
    assert(currentChild != null);
    return currentChild.getRealNode();
  }

  public function canBeUpdatedByNode(node:VNode):Bool {
    return node.type == componentType;
  }

  public function visitChildren(visitor:(child:ComponentBase) -> Bool) {
    if (currentChild != null) visitor(currentChild);
  }
}
