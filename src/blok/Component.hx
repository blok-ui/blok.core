package blok;

import haxe.Exception;
import haxe.ds.Option;
import blok.exception.*;
import blok.VNodeType;

using Lambda;

/**
  Blok apps are made up of declarative trees of Components, which
  do everything from displaying simple text to setting up states and
  services.
**/
@:nullSafety
@:allow(blok)
@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements Disposable {
  var __key:Null<Key> = null;
  var __status:ComponentLifecycle = ComponentPending;
  var __currentRevision:Int = 0;
  var __renderCount:Int = 0;
  var __lastRevision:Int = 0;
  var __effectQueue:Array<()->Void> = [];
  var __updateQueue:Array<Component> = [];
  var __scheduler:Null<Scheduler>;
  var __parent:Null<Component> = null;
  var __engine:Null<Engine> = null;
  var __children:Array<Component> = [];
  var __previousChildren:Null<Array<Component>> = null;

  abstract public function render():VNodeResult;

  abstract public function getComponentType():VNodeType;

  abstract public function updateComponentProperties(props:Dynamic):Void;
  
  /**
    Set up a component. Should only be called once, before the first render.
  **/
  public function initializeComponent(parent:Null<Component>, engine:Engine, ?key:Key) {
    switch __status {
      case ComponentPending:
        __status = ComponentInvalid;
        __key = key;
        __parent = parent;
        __engine = engine;
        __runInitHooks();
        __getEngine().plugins.wasInitialized(this);
      default:
        throw new ComponentRemountedException(this);
    }
  }

  /**
    Set up a component to be the root of a component tree.
  **/
  public inline function initializeRootComponent(engine:Engine) {
    initializeComponent(null, engine, null);
  }

  /**
    Render the component and diff its children.

    Note that this will run *immediately*, which is generally not the
    behavior you want. Only call this method if you have a really good
    reason -- otherwise, use `invalidateComponent`.
  **/
  public function renderComponent() {
    switch __status {
      case ComponentPending | ComponentDisposed:
        throw new ComponentNotMountedException(this);
      case ComponentRendering:
        throw new ComponentIsRenderingException(this);
      default:
        var engine = __getEngine();
        
        try {
          __updateQueue = [];
          __previousChildren = __children.copy();

          switch __status {
            case ComponentRecovering(_):
            default: __status = ComponentRendering;
          }

          engine.differ.patchComponent(this, __doRenderLifecycle());

          __status = ComponentValid;
          
          engine.plugins.wasRendered(this);

          __renderCount++;
          __previousChildren = null;

          __enqueueEffect(__runEffectHooks);
        } catch (e:BlokException) switch __status {
          case ComponentRecovering(_): 
            throw e;
          default:
            __status = ComponentRecovering(e);
            renderComponent();
        }
    }
  }

  /**
    Render a root component. This mostly just ensures that effects are 
    dispatched.
  **/
  public function renderRootComponent() {
    if (__parent != null) {
      throw new BlokException('Attempted to render a non-root component as a root component', this);
    }

    renderComponent();
    __dequeueEffects();
  }

  /**
    Mark this component as invalid and schedule it for rendering. 

    You should *always* use this method instead of `renderComponent`
    unless you know what you're doing.
  **/
  final public function invalidateComponent() {
    switch __status {
      case ComponentDisposed | ComponentPending:
        throw new ComponentNotMountedException(this);
      case ComponentRendering:
        throw new blok.exception.ComponentIsRenderingException(this);
      case ComponentInvalid:
        return;
      default:
        __status = ComponentInvalid;
        if (__parent == null) {
          __schedule(renderRootComponent);
        } else {
          __parent.__enqueueChildForUpdate(this);
        }
    }
  }

  /**
    Remove this component from the component tree.
  **/
  public function remove() {
    switch __status {
      case ComponentDisposed | ComponentPending:
        return;
      default:
        if (__parent != null) { 
          __parent.removeChild(this);
        } else {
          dispose();
        } 
    }
  }

  /**
    Dispose this component.

    Note that this will not remove the component from the
    tree -- call `remove` for that. This is done as the Engine
    needs to access disposed components in some cases.
  **/
  public function dispose() {
    switch __status {
      case ComponentDisposed:
        return;

      // todo: should there be errors if we're in the wrong
      //       part of the lifecycle?
      
      default:
        var engine = __getEngine();
        
        engine.plugins.willBeDisposed(this);
    
        __status = ComponentDisposed;

        for (child in __children) child.dispose();
        
        __engine = null;
    }
  }

  /**
    Check if this component has been invalidated (scheduled for a new render).

    Note that this is different from `shouldComponentRender`.
  **/
  public function componentIsInvalid():Bool {
    return switch __status {
      case ComponentInvalid: true;
      default: false;
    }
  }

  /**
    Check if this component has been mounted and initialized.
  **/
  public function componentIsMounted():Bool {
    return switch __status {
      case ComponentPending | ComponentDisposed: false;
      default: true;
    }
  }

  public function componentIsRenderingForTheFirstTime() {
    return __renderCount == 0;
  }

  /**
    Override `shouldComponentRender` to optimize when the component re-renders.

    The most common optimization is to only re-render when properties
    have changed. Use the `@lazy` class metadata to have Blok generate
    this code for you, or compare `__currentRevision` and `__lastRevision`
    to see if anything has changed.
  **/
  public function shouldComponentRender():Bool {
    return true;
  }
  
  /**
    Override to catch exceptions encountered during rendering or 
    `@before` and `@init` hooks. Note that exceptions in `@effect`
    hooks WILL NOT be caught.

    The `VNodeResult` returned from this method will be displayed in
    place of whatever was returned from `render`.
  **/
  public function componentDidCatch(exception:Exception):VNodeResult {
    throw exception;
    return [];
  }

  /**
    Get this component's unique key (if any).
  **/
  public inline function getComponentKey() {
    return __key;
  }
  
  /**
    Look up the tree to find a parent component of the given type.
  **/
  public function findParentOfType<T:Component>(kind:Class<T>):Option<T> {
    if (__parent == null) {
      if (Std.isOfType(this, kind)) return Some(cast this);
      return None;
    }
    
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findParentOfType(kind);
      case found: Some(cast found);
    }
  }

  public inline function getChildren() {
    return __children;
  }

  public inline function getPreviousChildren():Null<Array<Component>> {
    return __previousChildren;
  }

  public function addChild(component:Component) {
    __children.push(component);
  }

  public function removeChild(component:Component):Bool {
    if (component != null && hasChild(component)) {
      component.dispose();
      __children.remove(component);
      component.__parent = null;
      return true;
    }
    return false;
  }

  public function insertChildAt(pos:Int, component:Component) {
    __children.insert(pos, component);
  }

  public function setChildAt(pos:Int, component:Component) {
    __children[pos] = component;
  }

  public function getChildAt(pos:Int) {
    return __children[pos];
  }

  public function insertChildBefore(reference:Null<Component>, component:Component) {
    if (reference == null || !hasChild(reference)) {
      return addChild(component);
    }
    var pos = getChildPosition(reference);
    if (pos == 0) {
      insertChildAt(0, component);
    } else {
      insertChildAt(pos - 1, component);
    } 
  }

  public function insertChildAfter(reference:Null<Component>, component:Component) {
    if (reference == null || !hasChild(reference)) {
      return addChild(component);
    }
    var pos = getChildPosition(reference);
    if (pos >= __children.length) {
      addChild(component);
    } else {
      insertChildAt(pos + 1, component);
    }
  }

  public function moveChildTo(pos:Int, component:Component) {
    if (!__children.has(component)) {
      return insertChildAt(pos, component);
    }

    if (pos >= __children.length) {
      pos = __children.length;
    }
    
    var from = __children.indexOf(component);

    if (pos == from) return;
    
    if (from < pos) {
      var i = from;
      while (i < pos) {
        setChildAt(i, __children[i + 1]);
        i++;
      } 
    } else {
      var i = from;
      while (i > pos) {
        setChildAt(i, __children[i - 1]);
        i--;
      }
    }

    setChildAt(pos, component);
  }

  public function replaceChildAt(pos:Int, newComponent:Component) {
    var oldComponent = getChildAt(pos);
    if (oldComponent == newComponent) return;
    if (oldComponent == null) {
      insertChildAt(pos, newComponent);
    } else {
      insertChildBefore(oldComponent, newComponent);
      removeChild(oldComponent);
    }
  }

  public function replaceChild(oldComponent:Null<Component>, newComponent:Component) {
    if (oldComponent == newComponent) return;
    if (oldComponent == null || !hasChild(oldComponent)) {
      return addChild(newComponent);
    }
    insertChildBefore(oldComponent, newComponent);
    removeChild(oldComponent);
  }

  public function getChildPosition(component:Component) {
    return __children.indexOf(component);
  }

  public function hasChild(component:Component):Bool {
    return getChildPosition(component) > -1;
  }

  public function findChildByKey(key:Null<Key>):Null<Component> {
    if (key == null) return null;
    return __children.find(comp -> comp.__key == key);
  }

  public function findChildOfType<T:Component>(kind:Class<T>):Option<T> {
    var found = __children.find(c -> Std.isOfType(c, kind));
    if (found == null) return None;
    return Some(cast found);
  }
  
  function __getEngine():Engine {
    if (__engine != null) {
      return cast __engine;
    }

    throw new NoEngineException(this);
  }

  function __doRenderLifecycle():VNodeResult {
    var exception:Null<Exception> = null;
    var vnr:VNodeResult = new VNodeResult(VNone);
    var engine = __getEngine();

    try {
      __runBeforeHooks();
      vnr = switch __status {
        case ComponentRecovering(error):
          componentDidCatch(error);
        default:
          render();
      }
    } catch (e:BlokException) {
      exception = e;
    } catch (e) {
      exception = new WrappedException(e, this);
    }

    if (exception != null) throw exception;

    return engine.plugins.prepareVNodes(this, vnr);
  }
  
  function __schedule(cb:()->Void) {
    if (__scheduler != null) {
      __scheduler.schedule(cb);
    } else if (__parent != null) {
      __parent.__schedule(cb);
    } else {
      DefaultScheduler.getInstance().schedule(cb);
    }
  }

  abstract function __runBeforeHooks():Void;

  abstract function __runInitHooks():Void;

  abstract function __runEffectHooks():Void;
  
  function __enqueueChildForUpdate(child:Component) {
    if (componentIsInvalid() || __updateQueue.contains(child)) return;

    __updateQueue.push(child);

    if (__parent != null) {
      __parent.__enqueueChildForUpdate(this);
    } else {
      __schedule(__dequeueUpdates);
    }
  }

  function __dequeueUpdates() {
    if (__updateQueue.length == 0) return;
    var updates = __updateQueue.copy();
    
    __updateQueue = [];

    for (component in updates) {
      if (component.componentIsInvalid()) {
        component.renderComponent();
      } else {
        component.__dequeueUpdates();
      }
    }

    __dequeueEffects();
  }

  function __enqueueEffect(effect:()->Void) {
    if (__parent == null) {
      __effectQueue.push(effect);
    } else {
      __parent.__enqueueEffect(effect);
    }
  }

  function __dequeueEffects() {
    var effects = __effectQueue.copy();

    __effectQueue = [];
    
    for (fx in effects) fx();
  }
}
