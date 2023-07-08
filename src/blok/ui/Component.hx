package blok.ui;

import blok.debug.Debug;
import blok.adaptor.Adaptor;
import blok.core.*;

enum ComponentStatus {
  Pending;
  Valid;
  Invalid;
  Building;
  Disposing;
  Disposed;
}

@:allow(blok)
abstract class Component implements Disposable implements DisposableHost {
  var __node:VNode;
  var __status:ComponentStatus = Pending;
  var __slot:Null<Slot> = null;
  var __parent:Null<Component> = null;
  var __adaptor:Null<Adaptor> = null;
  var __invalidChildren:Array<Component> = [];

  final __disposables:DisposableCollection = new DisposableCollection();

  public function mount(parent:Null<Component>, slot:Null<Slot>) {
    __init(parent, slot);

    __status = Building;
    __initialize();
    __cleanupAfterValidation();
  }

  public function hydrate(cursor:Cursor, parent:Null<Component>, slot:Null<Slot>) {
    __init(parent, slot);

    __status = Building;
    __hydrate(cursor);
    __cleanupAfterValidation();
  }

  function __init(parent:Null<Component>, slot:Null<Slot>) {
    assert(__status == Pending, 'Attempted to initialize a component that has already been mounted');

    __parent = parent;
    __slot = slot;
    __adaptor = parent.getAdaptor();
  }

  public function update(node:VNode) {
    assert(__status != Building);

    if (__node == node) {
      __cleanupAfterValidation();
      return;
    }

    __status = Building;
    __node = node;
    __update();
    __cleanupAfterValidation();
  }

  public function invalidate() {
    assert(__status != Building);

    __status = Invalid;

    switch __parent {
      case null:
        scheduleValidation();
      case parent:
        parent.scheduleChildForValidation(this);
    }
  }

  public function validate() {
    if (__status != Invalid) {
      validateInvalidChildren();
      return;
    }

    assert(__status != Building);

    __status = Building;
    __validate();
    __cleanupAfterValidation();
  }

  abstract function __initialize():Void;
  abstract function __hydrate(cursor:Cursor):Void;
  abstract function __update():Void;
  abstract function __validate():Void;
  abstract function __dispose():Void;
  abstract function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>):Void;
  
  abstract public function getRealNode():Dynamic;
  abstract public function canBeUpdatedByNode(node:VNode):Bool;
  abstract public function visitChildren(visitor:(child:Component)->Bool):Void;

  public function findAncestor(match:(component:Component)->Bool):Maybe<Component> {
    return switch __parent {
      case null: None;
      case parent if (match(parent)): Some(parent);
      case parent: parent.findAncestor(match);
    }
  }

  public function findAncestorOfType<T:Component>(kind:Class<T>):Maybe<T> {
    if (__parent == null) return None;
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findAncestorOfType(kind);
      case found: Some(cast found);
    }
  }

  public function filterChildren(match:(child:Component) -> Bool, recursive:Bool = false):Array<Component> {
    var results:Array<Component> = [];
    
    visitChildren(child -> {
      if (match(child)) results.push(child);
      
      if (recursive) {
        results = results.concat(child.filterChildren(match, true));
      }

      true;
    });

    return results;
  }

  public function findChild(match:(child:Component) -> Bool, recursive:Bool = false):Maybe<Component> {
    var result:Null<Component> = null;

    visitChildren(child -> {
      if (match(child)) {
        result = child;
        return false;
      }
      true;
    });

    return switch result {
      case null if (recursive):
        visitChildren(child -> switch child.findChild(match, true) {
          case Some(value):
            result = value;
            false;
          case None:
            true;
        });
        if (result == null) None else Some(result);
      case null: 
        None;
      default: 
        Some(result);
    }
  }

  public function filterChildrenOfType<T:Component>(kind:Class<T>, recursive:Bool = false):Array<T> {
    return cast filterChildren(child -> Std.isOfType(child, kind), recursive);
  }

  public function findChildOfType<T:Component>(kind:Class<T>, recursive:Bool = false):Maybe<T> {
    return cast findChild(child -> Std.isOfType(child, kind), recursive);
  }

  public function getAdaptor() {
    assert(__adaptor != null);
    return __adaptor;
  }

  function createSlot(index:Int, previous:Null<Component>):Slot {
    return new Slot(index, previous);
  }

  function updateSlot(slot:Null<Slot>):Void {
    if (__slot == slot) return;
    var oldSlot = __slot;
    __slot = slot;
    __updateSlot(oldSlot, __slot);
  }

  function scheduleValidation() {
    var adaptor = getAdaptor();
    adaptor.schedule(validate);
  }

  function __cleanupAfterValidation() {
    if (__invalidChildren.length > 0) __invalidChildren = [];
    if (__status != Invalid) __status = Valid;
  }

  function scheduleChildForValidation(child:Component) {
    if (__status == Invalid) return;
    if (__invalidChildren.contains(child)) return;
    
    __invalidChildren.push(child);

    if (__parent == null) {
      scheduleValidation();
      return;
    }

    __parent.scheduleChildForValidation(this);
  }

  function validateInvalidChildren() {
    if (__invalidChildren.length == 0) return;

    var children = __invalidChildren.copy();
    __invalidChildren = [];

    for (child in __invalidChildren) child.validate();
  }

  public function addDisposable(disposable:DisposableItem) {
    __disposables.addDisposable(disposable);
  }

  public function dispose() {
    assert(__status != Building, 'Attempted to dispose a component while it was building');
    assert(__status != Disposing, 'Attempted to dispose a component that is already disposing');
    assert(__status != Disposed, 'Attempted to dispose a component that was already disposed');

    __status = Disposing;
    __slot = null;
    __dispose();
    __disposables.dispose();

    visitChildren(child -> {
      child.dispose();
      return true;
    });
    
    __status = Disposed;
  }
}
