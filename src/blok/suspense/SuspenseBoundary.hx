package blok.suspense;

import blok.debug.Debug.error;
import blok.debug.Debug.assert;
import blok.diffing.Differ;
import blok.adaptor.Cursor;
import blok.boundary.Boundary;
import blok.ui.*;

using blok.boundary.BoundaryTools;

enum SuspenseBoundaryStatus {
  Ok;
  Suspended(remaining:Int);
}

typedef SuspenseBoundaryProps = {
  public final child:Child;
  public final fallback:()->Child;
  public final ?onComplete:()->Void;
  public final ?onSuspended:()->Void;
} 

// @todo: I'm not convinced this thing actually always works -- I think
// it might render nothing sometimes, but I can't get that to replicate
// with the limited tests I have. 
class SuspenseBoundary extends ComponentBase implements Boundary {
  public static final componentType:UniqueId = new UniqueId();
  
  public static function node(props:SuspenseBoundaryProps, ?key) {
    return new VComponent(componentType, props, SuspenseBoundary.new, key);
  }

  var child:Child;
  var fallback:()->Child;
  var onComplete:Null<()->Void>;
  var onSuspended:Null<()->Void>;
  var hydrating:Bool = false;
  var suspenseStatus:SuspenseBoundaryStatus = Ok;
  var hiddenRoot:Null<ComponentBase> = null;
  var hiddenSlot:Null<Slot> = null;
  var realChild:Null<ComponentBase> = null;
  var currentChild:Null<ComponentBase> = null;

  function new(node) {
    __node = node;
    var props:SuspenseBoundaryProps = __node.getProps();
    this.child = props.child;
    this.fallback = props.fallback;
    this.onComplete = props.onComplete;
    this.onSuspended = props.onSuspended;
  }

  function updateProps() {
    var props:SuspenseBoundaryProps = __node.getProps();
    this.child = props.child;
    this.fallback = props.fallback;
    this.onComplete = props.onComplete;
    this.onSuspended = props.onSuspended;
  }

  function setActiveChild() {
    switch suspenseStatus {
      case Suspended(_) if (currentChild != realChild):
      case Suspended(_):
        realChild.updateSlot(hiddenSlot);
        currentChild = fallback().createComponent();
        currentChild.mount(this, __slot);
      case Ok:
        if (currentChild != realChild) currentChild?.dispose();
        currentChild = realChild;
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
    hiddenSlot = createSlot(0, hiddenRoot.findChildOfType(Placeholder).unwrap());
  }

  public function handle(component:ComponentBase, object:Any) {
    if (object is SuspenseException) {
      if (hydrating) error('SuspenseBoundary suspended during hydration.');

      var suspense:SuspenseException = object;

      suspenseStatus = switch suspenseStatus {
        case Suspended(remaining): 
          Suspended(remaining + 1);
        case Ok: 
          if (onSuspended != null) onSuspended();
          Suspended(1);
      }
      
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
            case Ok: Ok;
          }
          if (suspenseStatus == Ok) {
            setActiveChild();
            if (onComplete != null) onComplete();
          }
        case Error(error):
          switch __status {
            case Disposing | Disposed: return;
            default:
          }
          this.tryToHandleWithBoundary(error);
      });
  
      return;
    }

    this.tryToHandleWithBoundary(object);
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
    updateProps();
    if (currentChild != realChild) currentChild.dispose();
    currentChild = realChild = updateChild(this, realChild, child, __slot);
    setActiveChild();
  }

  function __validate() {
    currentChild = realChild = updateChild(this, realChild, child, __slot);
    setActiveChild();
  }

  function __dispose() {
    hiddenRoot?.dispose();
    hiddenRoot = null;
    hiddenSlot = null;
    currentChild?.dispose();
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
