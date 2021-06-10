package blok;

import haxe.Exception;
import haxe.ds.Option;
import blok.exception.*;
import blok.VNodeType;

using Lambda;

@:nullSafety
@:allow(blok)
@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements Disposable {
  var __key:Null<Key> = null;
  var __isMounted:Bool = false;
  var __isInvalid:Bool = false;
  var __isDisposed:Bool = false;
  var __isFirstRender:Bool = true;
  var __isRendering:Bool = false;
  var __isRecoveringFrom:Null<BlokException> = null;
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __effectQueue:Array<()->Void> = [];
  var __updateQueue:Array<Component> = [];
  var __scheduler:Null<Scheduler>;
  var __differ:Null<Differ> = null;
  var __parent:Null<Component> = null;
  var __children:Array<Component> = [];

  abstract public function render():VNode;

  abstract public function getComponentType():VNodeType;

  abstract public function updateComponentProperties(props:Dynamic):Void;
  
  public function initializeComponent(?parent:Component, ?key:Key) {
    if (__isMounted) throw new ComponentRemountedException(this);
    
    __key = key;
    __isMounted = true;
    __parent = parent;
    __runInitHooks();
  }

  public function renderComponent() {
    __isInvalid = false;
    
    if (__isDisposed || !__isMounted) throw new ComponentNotMountedException(this);
    if (__isRendering) throw new ComponentIsRenderingException(this);
    
    try {
      __updateQueue = []; // Always clear the queue.
      __isRendering = true;
      __getDiffer().patchComponent(this, [ __doRenderLifecycle() ], __isFirstRender);
      __isRendering = false;
      __isFirstRender = false;
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

  public function initializeRootComponent(differ:Differ) {
    __differ = differ;
    initializeComponent();
    renderComponent();
    __dequeueEffects();
  }

  public function patchRootComponent() {
    if (__parent != null) 
      throw new BlokException('Cannot patch a non-root component', this);
    
    renderComponent();
    __dequeueEffects();
  }

  public function remove() {
    if (__isDisposed) return;
    if (__parent != null) { 
      __parent.removeComponent(this);
    } else {
      dispose();
    } 
  }

  public function dispose() {
    if (__isDisposed) return;
    __isDisposed = true;
    for (child in __children) child.dispose();
  }

  public function isComponentLive() {
    if (!__isMounted) return false;
    if (__parent != null) return __parent.isComponentLive();
    return true;
  }

  public inline function getComponentKey() {
    return __key;
  }
  
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

  public inline function getChildComponents() {
    return __children;
  }

  public function componentIsInvalid():Bool {
    return __isInvalid;
  }
  
  public function componentDidCatch(exception:Exception):VNode {
    throw exception;
    return new VFragment([]);
  }

  public function shouldComponentUpdate():Bool {
    return true;
  }

  public function addComponent(component:Component) {
    __children.push(component);
  }

  public function removeComponent(component:Component):Bool {
    if (component != null && hasComponent(component)) {
      component.dispose();
      __children.remove(component);
      return true;
    }
    return false;
  }

  public function insertComponentAt(pos:Int, component:Component) {
    __children.insert(pos, component);
  }

  public function setComponentAt(pos:Int, component:Component) {
    __children[pos] = component;
  }

  public function getComponentAt(pos:Int) {
    return __children[pos];
  }

  public function insertComponentBefore(reference:Null<Component>, component:Component) {
    if (reference == null || !hasComponent(reference)) {
      return addComponent(component);
    }
    var pos = getPositionOfComponent(reference);
    if (pos == 0) {
      insertComponentAt(0, component);
    } else {
      insertComponentAt(pos - 1, component);
    } 
  }

  public function insertComponentAfter(reference:Null<Component>, component:Component) {
    if (reference == null || !hasComponent(reference)) {
      return addComponent(component);
    }
    var pos = getPositionOfComponent(reference);
    if (pos >= __children.length) {
      addComponent(component);
    } else {
      insertComponentAt(pos + 1, component);
    }
  }

  public function moveComponentTo(pos:Int, component:Component) {
    if (!__children.has(component)) {
      return insertComponentAt(pos, component);
    }

    if (pos >= __children.length) {
      pos = __children.length;
    }
    
    var from = __children.indexOf(component);
    if (pos == from) return;

    // Note: there may be a better sorting algo than this
    if (from < pos) {
      var i = from;
      while (i < pos) {
        setComponentAt(i, __children[i + 1]);
        i++;
      } 
    } else {
      var i = from;
      while (i > pos) {
        setComponentAt(i, __children[i - 1]);
        i--;
      }
    }

    setComponentAt(pos, component);
  }

  public function replaceComponentAt(pos:Int, newComponent:Component) {
    var oldComponent = getComponentAt(pos);
    if (oldComponent == newComponent) return;
    if (oldComponent == null) {
      insertComponentAt(pos, newComponent);
    } else {
      insertComponentBefore(oldComponent, newComponent);
      removeComponent(oldComponent);
    }
  }

  public function replaceComponent(oldComponent:Null<Component>, newComponent:Component) {
    if (oldComponent == newComponent) return;
    if (oldComponent == null || !hasComponent(oldComponent)) {
      return addComponent(newComponent);
    }
    insertComponentBefore(oldComponent, newComponent);
    removeComponent(oldComponent);
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

  public function findComponentOfType<T:Component>(kind:Class<T>):Option<T> {
    var found = __children.find(c -> Std.isOfType(c, kind));
    if (found == null) return None;
    return Some(cast found);
  }
  
  function __doRenderLifecycle():VNode {
    var exception:Null<Exception> = null;
    var vn:Null<VNode> = null;

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

    return __ensureVNode(vn);
  }

  function __ensureVNode(vn:Null<VNode>):VNode {
    if (vn == null) {
      return __getDiffer().getPlaceholder();
    }
    if (vn.type == fragmentType && (vn.children == null || vn.children.length == 0)) {
      return __getDiffer().getPlaceholder();
    }
    return vn; 
  }

  function __getDiffer():Differ {
    return if (__differ != null) {
      cast __differ; // I promise you null safety, I just checked.
    } else if (__parent != null) {
      __parent.__getDiffer();
    } else {
      Differ.getInstance();
    }
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
    return try render() catch (e) null;
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
