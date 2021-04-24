package blok;

import haxe.ds.Option;
import blok.core.Rendered;
import blok.exception.*;

@:nullSafety
@:allow(blok)
@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements Disposable {
  var __isMounted:Bool = false;
  var __isInvalid:Bool = false;
  var __currentRevision:Int = 0;
  var __lastRevision:Int = 0;
  var __engine:Null<Engine>;
  var __effectQueue:Array<()->Void> = [];
  var __updateQueue:Array<Component> = [];
  var __parent:Null<Component> = null;
  var __renderedChildren:Rendered = new Rendered();

  public function initializeComponent(engine:Engine, ?parent:Component) {
    if (__isMounted) throw new ComponentRemountedException();
    __isMounted = true;
    __runInitHooks();
    __engine = engine;
    __parent = parent;
    __renderedChildren = __engine.initialize(this);
    __enqueueEffect(__runEffectHooks);
  }
  
  public function updateComponentProperties(props:Dynamic) {
    // noop
  }

  final public function updateComponent() {
    if (!__isMounted || __engine == null) throw new ComponentNotMountedException();
    if (__isInvalid) return;

    __isInvalid = true;
    if (__parent == null) {
      __engine.schedule(() -> {
        renderComponent();
        __dequeueEffects();
      });
    } else {
      __parent.__enqueueChildForUpdate(this);
    } 
  } 

  public function renderComponent() {
    __isInvalid = false;
    
    if (!__isMounted || __engine == null) throw new ComponentNotMountedException();

    __runBeforeHooks();
    
    __renderedChildren = __engine.update(this);
    __enqueueEffect(__runEffectHooks);
  }
  
  abstract function render():VNode;

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
  
  public function findInheritedComponentOfType<T:Component>(kind:Class<T>):Option<T> {
    if (__parent == null) return None; 
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findInheritedComponentOfType(kind);
      case found: Some(cast found);
    }
  }
  
  function __runInitHooks():Void {
    // noop
  }

  function __runBeforeHooks():Void {
    // noop
  }

  function __runEffectHooks() {
    // noop
  }

  
  function __enqueueChildForUpdate(child:Component) {
    if (componentIsInvalid() || __updateQueue.contains(child)) return;

    __updateQueue.push(child);

    if (__parent != null) {
      __parent.__enqueueChildForUpdate(this);
    } else {
      if (__engine == null) throw new ComponentNotMountedException();
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
