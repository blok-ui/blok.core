package blok;

import haxe.Exception;
import haxe.ds.Option;
import blok.exception.*;

using Lambda;

@:nullSafety
@:allow(blok)
@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements Disposable {
  var __key:Null<Key> = null;
  var __isMounted:Bool = false;
  var __isInvalid:Bool = false;
  var __isRendering:Bool = false;
  var __isRecoveringFrom:Null<BlokException> = null;
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __effectQueue:Array<()->Void> = [];
  var __updateQueue:Array<Component> = [];
  var __scheduler:Null<Scheduler>;
  var __parent:Null<Component> = null;
  var __children:Array<Component> = [];

  public function initializeComponent(?parent:Component, ?key:Key) {
    if (__isMounted) throw new ComponentRemountedException(this);
    
    try {
      __key = key;
      __isMounted = true;
      __parent = parent;
      __runInitHooks();
      __doInitialize();
      __enqueueEffect(__runEffectHooks);
    } catch (e:BlokException) {
      __isRendering = false;
      if (__isRecoveringFrom != null) throw e;
      __isMounted = false;
      __isRecoveringFrom = e;
      initializeComponent(parent, key);
      __isRecoveringFrom = null;
    }
  }

  final public function renderComponent() {
    __isInvalid = false;
    
    if (!__isMounted) throw new ComponentNotMountedException(this);
    if (__isRendering) throw new ComponentIsRenderingException(this);
    
    try {
      __isRendering = true;
      __doUpdate();
      __isRendering = false;
      __enqueueEffect(__runEffectHooks);
    } catch (e:BlokException) {
      __isRendering = false;
      if (__isRecoveringFrom != null) throw e;
      __isRecoveringFrom = e;
      renderComponent();
      __isRecoveringFrom = null;
    }
  }

  final public function updateComponent() {
    if (!__isMounted) throw new ComponentNotMountedException(this);
    if (__isInvalid) return;
    
    __isInvalid = true;
    
    if (__parent == null) {
      __schedule(patchRootComponent);
    } else {
      __parent.__enqueueChildForUpdate(this);
    }
  }

  public function initializeRootComponent() {
    initializeComponent();
    __dequeueEffects();
  }

  public function patchRootComponent() {
    if (__parent != null) 
      throw new BlokException('Cannot patch a non-root component', this);
    
    renderComponent();
    __dequeueEffects();
  }

  public function dispose() {
    for (child in __children) child.dispose();
    if (__parent != null) __parent.__children.remove(this);
    __parent = null;
  }

  public function shouldComponentUpdate():Bool {
    return true;
  }

  public function componentIsInvalid():Bool {
    return __isInvalid;
  }

  public function componentDidCatch(exception:Exception):VNode {
    throw exception;
    return VNone;
  }
  
  abstract public function render():VNode;

  abstract public function updateComponentProperties(props:Dynamic):Void;

  abstract public function isComponentType(type:ComponentType<Dynamic, Dynamic>):Bool;
  
  public function findInheritedComponentOfType<T:Component>(kind:Class<T>):Option<T> {
    if (__parent == null) {
      if (Std.isOfType(this, kind)) return Some(cast this);
      return None;
    }
    
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findInheritedComponentOfType(kind);
      case found: Some(cast found);
    }
  }

  public function addComponent(component:Component, ?key:Key) {
    __children.push(component);
    component.initializeComponent(this, key);
  }

  public function removeComponent(component:Component) {
    if (hasComponent(component)) component.dispose();
  }

  public function insertComponentAt(pos:Int, component:Component, ?key:Key) {
    __children.insert(pos, component);
    component.initializeComponent(this, key);
  }

  public function moveComponentTo(pos:Int, component:Component) {
    if (!__children.has(component)) return;
    __children.remove(component);
    __children.insert(pos, component);
  }

  public function getComponentAt(pos:Int) {
    return __children[pos];
  }

  public function repaceComponentAt(pos:Int, component:Component) {
    var comp = getComponentAt(pos);
    if (comp != null) {
      comp.dispose();
      insertComponentAt(pos, component, comp.__key);
    }
  }

  public function replaceComponentByKey(key:Key, component:Component) {
    var comp = findComponentByKey(key);
    if (comp != null) {
      var pos = getPositionOfComponent(comp);
      comp.dispose();
      insertComponentAt(pos, component, key);
    }
  }

  public function replaceComponent(oldComponent:Component, newComponent:Component) {
    if (!hasComponent(oldComponent)) {
      addComponent(newComponent, oldComponent.__key);
    }
    var pos = getPositionOfComponent(oldComponent);
    oldComponent.dispose();
    insertComponentAt(pos, newComponent, oldComponent.__key);
  }

  public function getPositionOfComponent(component:Component) {
    return __children.indexOf(component);
  }

  public function hasComponent(component:Component):Bool {
    return getPositionOfComponent(component) > -1;
  }

  public function findComponentByKey(key:Null<Key>):Null<Component> {
    if (key == null) return null;
    return __children.find(comp -> comp.__key == key);
  }
  
  function __doInitialize() {
    Differ.initialize(__doRenderLifecycle(), this); 
  }

  function __doUpdate() {
    Differ.diff(__doRenderLifecycle(), this);
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

  function __renderFallbackForException():VNode {
    return try render() catch (e) VNone;
  }

  abstract function __runBeforeHooks():Void;

  abstract function __runInitHooks():Void;

  abstract function __runEffectHooks():Void;

  function __doRenderLifecycle():VNode {
    var exception:Null<Exception> = null;
    var vn:VNode = VNone;

    try {
      __runBeforeHooks();
      vn = if (__isRecoveringFrom != null)
        componentDidCatch(__isRecoveringFrom)
      else 
        render();
    } catch (e:BlokException) {
      exception = e;
    } catch (e) {
      exception = new WrappedException(e, this);
    }

    if (exception != null) throw exception;

    return vn;
  }
  
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
