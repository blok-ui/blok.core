package blok.ui;

import haxe.ds.Option;
import blok.exception.*;
import blok.core.Disposable;
import blok.core.DisposableHost;

/**
  The basic building-block of everything in Blok is the Widget. You
  generally won't use Widgets directly -- instead, you should use
  Components, which provide a number of macro-based features
  to make things easier. Widgets are a lower-level class
  that can be used where the Component API is overkill (such as
  the `ElementWidget` or `TextWidget` in `blok.platform.dom`).
**/
@:nullSafety
@:allow(blok)
abstract class Widget implements Disposable implements DisposableHost {
  var __key:Null<Key> = null;
  var __parent:Null<Widget> = null;
  var __platform:Null<Platform> = null;
  var __children:WidgetList = [];
  var __status:WidgetLifecycle = WidgetPending;
  var __pendingUpdates:Array<Widget> = [];
  var __disposables:Array<Disposable> = [];

  abstract public function getWidgetType():WidgetType;

  public function getWidgetKey() {
    return __key;
  }

  public function initializeWidget(?parent:Widget, platform:Platform, ?key:Key) {
    switch __status {
      case WidgetPending:
        __status = WidgetInvalid;
        __parent = parent;
        __key = key;
        __registerPlatform(platform);
        __initHooks();
      default:
        throw new WidgetRemountedException(this);
    }
  }

  function __registerPlatform(platform:Platform) {
    __platform = platform;
  }

  function __initHooks():Void {
    // noop
  }

  public function scheduleChildForUpdate(widget:Widget) {
    switch __status {
      case WidgetInvalid:
      default:
        if (!__pendingUpdates.contains(widget)) {
          __pendingUpdates.push(widget);
        }
    
        if (__parent == null) {
          scheduleUpdatePendingChildren();
        } else {
          __parent.scheduleChildForUpdate(this);
        }
    }
  }

  public function invalidateWidget() {
    switch __status {
      case WidgetInvalid:
        // noop
      case WidgetPending | WidgetDisposed:
        throw new WidgetNotMountedException(this);
      case WidgetUpdating:
        throw new WidgetIsUpdatingException(this);
      default:
        __status = WidgetInvalid;
        if (__parent == null) {
          schedulePerformUpdate();
        } else {
          __parent.scheduleChildForUpdate(this);
        }
    }
  }

  public function updatePendingChildren(effects:Effect) {
    if (__pendingUpdates.length == 0) return;
    var updates = __pendingUpdates.copy();
    __pendingUpdates = [];
    for (child in updates) switch child.__status {
      case WidgetInvalid:
        child.performUpdate(effects);
      default:
        child.updatePendingChildren(effects);
    }
  }

  public function scheduleUpdatePendingChildren() {
    if (__platform == null) throw new NoPlatformException(this);
    __platform.schedule(updatePendingChildren);
  }

  public function performUpdate(effects:Effect) {
    __pendingUpdates = [];
    switch __status {
      case WidgetPending | WidgetDisposed:
        throw new WidgetNotMountedException(this);
      case WidgetUpdating:
        throw new WidgetIsUpdatingException(this);
      default: 
        __status = WidgetUpdating;
        __performUpdate(effects);
        __status = WidgetValid;
    }
  }

  public function schedulePerformUpdate() {
    if (__platform == null) throw new NoPlatformException(this);
    __platform.schedule(performUpdate);
  }

  abstract public function __performUpdate(effects:Effect):Void;

  public function dispose() {
    switch __status {
      case WidgetDisposed:
        return;
      default:
        __status = WidgetDisposed;
        for (child in __children) child.dispose();
        for (disposable in __disposables) disposable.dispose();
        __disposables = [];
        __children = [];
    }
  }

  public function addDisposable(disposable:Disposable) {
    __disposables.push(disposable);
  }

  public function findParentOfType<T:Widget>(kind:Class<T>):Option<T> {
    if (__parent == null) {
      if (Std.isOfType(this, kind)) return Some(cast this);
      return None;
    }
    
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findParentOfType(kind);
      case found: Some(cast found);
    }
  }

  public inline function getPlatform() {
    return __platform;
  }

  public inline function getChildren() {
    return __children;
  }
  
  abstract public function getApplicator():Applicator;

  public inline function getChildApplicators():Array<Applicator> {
    return [ for (child in __children) child.getApplicator() ];
  }

  public inline function hasChild(widget:Widget) {
    return __children.has(widget);
  }

  public function addChild(widget:Widget) {
    getApplicator().addConcreteChild(widget);
    __children.add(widget);
  }

  public function removeChild(widget:Widget) {
    if (widget != null && __children.has(widget)) {
      getApplicator().removeConcreteChild(widget);
      widget.dispose();
      widget.__parent = null;
      __children.remove(widget);
      return true;
    }
    return false;
  }

  public function insertChildAt(pos:Int, widget:Widget) {
    getApplicator().insertConcreteChildAt(pos, widget);
    __children.insert(pos, widget);
  }

  public function getChildAt(pos:Int) {
    return __children.get(pos);
  }

  public function insertChildBefore(reference:Null<Widget>, widget:Widget) {
    if (reference == null || !__children.has(reference)) {
      return addChild(widget);
    }
    var pos = __children.indexOf(reference);
    if (pos == 0) {
      insertChildAt(0, widget);
    } else {
      insertChildAt(pos - 1, widget);
    } 
  }

  public function insertChildAfter(reference:Null<Widget>, widget:Widget) {
    if (reference == null || !__children.has(reference)) {
      return addChild(widget);
    }
    var pos = __children.indexOf(reference);
    if (pos >= __children.length) {
      addChild(widget);
    } else {
      insertChildAt(pos + 1, widget);
    }
  }

  public function moveChildTo(pos:Int, widget:Widget) {
    getApplicator().moveConcreteChildTo(pos, widget);

    if (!__children.has(widget)) {
      __children.insert(pos, widget);
      return;
    }

    if (pos >= __children.length) {
      pos = __children.length;
    }
    
    var from = __children.indexOf(widget);

    if (pos == from) return;
    
    if (from < pos) {
      var i = from;
      while (i < pos) {
        __children.set(i, __children.get(i + 1));
        i++;
      } 
    } else {
      var i = from;
      while (i > pos) {
        __children.set(i, __children.get(i - 1));
        i--;
      }
    }

    __children.set(pos, widget);
  }

  public function replaceChildAt(pos:Int, newWidget:Widget) {
    var oldWidget = getChildAt(pos);
    if (oldWidget == newWidget) return;
    if (oldWidget == null) {
      insertChildAt(pos, newWidget);
    } else {
      insertChildAfter(oldWidget, newWidget);
      removeChild(oldWidget);
    }
  }

  public function replaceChild(oldWidget:Null<Widget>, newWidget:Widget) {
    if (oldWidget == newWidget) return;
    if (oldWidget == null || !__children.has(oldWidget)) {
      return addChild(newWidget);
    }
    insertChildAfter(oldWidget, newWidget);
    removeChild(oldWidget);
  }

  public function getPositionOfChild(widget:Widget) {
    return __children.indexOf(widget);
  }

  public function findChildByKey(key:Null<Key>):Null<Widget> {
    if (key == null) return null;
    return __children.find(widget -> widget.__key == key);
  }

  public function findChildOfType<T:Widget>(kind:Class<T>):Option<T> {
    var found = __children.find(c -> Std.isOfType(c, kind));
    if (found == null) return None;
    return Some(cast found);
  }
}