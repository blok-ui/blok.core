package blok;

import haxe.Exception;
import haxe.ds.Option;
import blok.core.Rendered;
import blok.exception.*;

@:nullSafety
@:allow(blok)
@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements Disposable {
  var __isMounted:Bool = false;
  var __isInvalid:Bool = false;
  var __isRendering:Bool = false;
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __engine:Null<Engine>;
  var __effectQueue:Array<()->Void> = [];
  var __updateQueue:Array<Component> = [];
  var __parent:Null<Component> = null;
  var __renderedChildren:Rendered = new Rendered();

  public function initializeComponent(engine:Engine, ?parent:Component) {
    if (__isMounted || __engine != null) throw new ComponentRemountedException(this);
    __isMounted = true;
    __runInitHooks();
    __engine = engine;
    __parent = parent;
    __renderedChildren = __engine.initialize(this);
    __enqueueEffect(__runEffectHooks);
  }

  final public function updateComponent() {
    if (!__isMounted) throw new ComponentNotMountedException(this);
    if (__engine == null) throw new NoEngineException(this);
    if (__isInvalid) return;

    __isInvalid = true;

    if (__parent == null) {
      __engine.schedule(patchRootComponent);
    } else {
      __parent.__enqueueChildForUpdate(this);
    } 
  }

  public function renderComponent() {
    __isInvalid = false;
    
    if (!__isMounted) throw new ComponentNotMountedException(this);
    if (__engine == null) throw new NoEngineException(this);
    
    __renderedChildren = __engine.update(this);
    __enqueueEffect(__runEffectHooks);
  }
  
  public function initializeRootComponent(engine:Engine) {
    initializeComponent(engine);
    __dequeueEffects();
  }

  public function patchRootComponent() {
    if (__parent != null) 
      throw new BlokException('Cannot patch a non-root component', this);
    
    renderComponent();
    __dequeueEffects();
  }

  public function dispose() {
    for (registry in __renderedChildren.types) {
      registry.each(comp -> comp.dispose());
    }
    __renderedChildren = new Rendered();

    if (__engine == null) return;

    __engine.remove(this);
    __engine = null;
  }

  public function shouldComponentUpdate():Bool {
    return true;
  }

  public function componentIsInvalid() {
    return __isInvalid;
  }

  public function componentDidCatch(exception:Exception) {
    __bubbleExceptionUpwards(exception);
  }
  
  public function findInheritedComponentOfType<T:Component>(kind:Class<T>):Option<T> {
    if (__parent == null) return None; 
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findInheritedComponentOfType(kind);
      case found: Some(cast found);
    }
  }
  
  abstract public function updateComponentProperties(props:Dynamic):Void;

  abstract public function render():VNode;

  abstract function __runBeforeHooks():Void;

  abstract function __runInitHooks():Void;

  abstract function __runEffectHooks():Void;

  function __doRenderLifecycle():VNode {
    var exception:Null<Exception> = null;

    __runBeforeHooks();
    __isRendering = true;
    var vn:VNode = try render() catch (e) {
      // @todo: We should wrap the exception here to ensure we have
      //        access to the component tree and know where the exception
      //        happened. Maybe only a debug feature?
      exception = e;
      // @todo: What should be returned here?
      None;
    }
    __isRendering = false;

    if (exception != null) componentDidCatch(exception);

    return vn;
  }

  function __bubbleExceptionUpwards(exception:Exception) {
    if (__parent == null) {
      throw exception;
    } else {
      __parent.componentDidCatch(exception);
    }
  }
  
  function __enqueueChildForUpdate(child:Component) {
    if (componentIsInvalid() || __updateQueue.contains(child)) return;

    __updateQueue.push(child);

    if (__parent != null) {
      __parent.__enqueueChildForUpdate(this);
    } else {
      if (__engine == null) throw new NoEngineException(this);
      __engine.schedule(__dequeueUpdates);
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
