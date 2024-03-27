package blok.ui;

import blok.adaptor.*;
import blok.core.*;
import blok.debug.Debug;

enum abstract ComponentStatus(#if debug String #else Int #end) {
  final Pending;
  final Valid;
  final Invalid;
  final Rendering;
  final Disposing;
  final Disposed;
}

enum abstract ComponentRenderMode(Int) {
  final Normal;
  final Hydrating;
}

@:allow(blok)
abstract class View implements Disposable implements DisposableHost {
  var __node:VNode;
  var __status:ComponentStatus = Pending;
  var __slot:Null<Slot> = null;
  var __parent:Null<View> = null;
  var __adaptor:Null<Adaptor> = null;
  var __invalidChildren:Array<View> = [];
  var __renderMode:ComponentRenderMode = Normal;

  final __disposables:DisposableCollection = new DisposableCollection();

  public function mount(parent:Null<View>, slot:Null<Slot>) {
    __init(parent, slot);

    __status = Rendering;
    __renderMode = Normal;
    try __initialize() catch (e) {
      __cleanupAfterValidation();
      throw e;  
    };
    __cleanupAfterValidation();
  }

  public function hydrate(cursor:Cursor, parent:Null<View>, slot:Null<Slot>) {
    __init(parent, slot);

    __status = Rendering;
    __renderMode = Hydrating;
    try __hydrate(cursor) catch (e) {
      __cleanupAfterValidation();
      throw e;  
    };
    __cleanupAfterValidation();
  }

  function __init(parent:Null<View>, slot:Null<Slot>) {
    assert(__status == Pending, 'Attempted to initialize a component that has already been mounted');

    __parent = parent;
    __slot = slot;
    if (__adaptor == null) {
      assert(parent != null);
      __adaptor = parent.getAdaptor();
    }
  }

  public function update(node:VNode) {
    assert(__status != Rendering);

    if (__node == node) {
      __cleanupAfterValidation();
      return;
    }
  
    __status = Rendering;
    __renderMode = Normal;
    __node = node;
    __update();
    __cleanupAfterValidation();
  }

  public function invalidate() {
    if (__status == Invalid) return;

    __status = Invalid;

    switch __parent {
      case null:
        scheduleValidation();
      case parent:
        parent.scheduleChildForValidation(this);
    }
  }

  public function validate() {
    assert(__status != Rendering, 'Attempted to validate a Component that was already building');
    assert(__status != Disposing, 'Attempted to validate a Component that was disposing');
    assert(__status != Disposed, 'Attempted to validate a Component that was disposed');

    if (__status != Invalid) {
      validateInvalidChildren();
      return;
    }

    __status = Rendering;
    __renderMode = Normal;
    __validate();
    __cleanupAfterValidation();
  }

  abstract function __initialize():Void;
  abstract function __hydrate(cursor:Cursor):Void;
  abstract function __update():Void;
  abstract function __validate():Void;
  abstract function __dispose():Void;
  abstract function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>):Void;
  
  abstract public function getPrimitive():Dynamic;
  abstract public function canBeUpdatedByNode(node:VNode):Bool;
  abstract public function visitChildren(visitor:(child:View)->Bool):Void;

  public function findAncestor(match:(component:View)->Bool):Maybe<View> {
    return switch __parent {
      case null: None;
      case parent if (match(parent)): Some(parent);
      case parent: parent.findAncestor(match);
    }
  }

  public function findAncestorOfType<T:View>(kind:Class<T>):Maybe<T> {
    if (__parent == null) return None;
    return switch (Std.downcast(__parent, kind):Null<T>) {
      case null: __parent.findAncestorOfType(kind);
      case found: Some(cast found);
    }
  }

  public function filterChildren(match:(child:View) -> Bool, recursive:Bool = false):Array<View> {
    var results:Array<View> = [];

    visitChildren(child -> {
      if (match(child)) results.push(child);
      
      if (recursive) {
        results = results.concat(child.filterChildren(match, true));
      }

      true;
    });

    return results;
  }

  public function findChild(match:(child:View) -> Bool, recursive:Bool = false):Maybe<View> {
    var result:Null<View> = null;

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

  public function filterChildrenOfType<T:View>(kind:Class<T>, recursive:Bool = false):Array<T> {
    return cast filterChildren(child -> Std.isOfType(child, kind), recursive);
  }

  public function findChildOfType<T:View>(kind:Class<T>, recursive:Bool = false):Maybe<T> {
    return cast findChild(child -> Std.isOfType(child, kind), recursive);
  }

  public function getAdaptor() {
    assert(__adaptor != null);
    return __adaptor;
  }

  function createSlot(index:Int, previous:Null<View>):Slot {
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
    adaptor.schedule(() -> validate());
  }

  function __cleanupAfterValidation() {
    __renderMode = Normal;
    if (__invalidChildren.length > 0) __invalidChildren = [];
    if (__status != Invalid) __status = Valid;
  }

  function scheduleChildForValidation(child:View) {
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

    for (child in children) child.validate();
  }

  public function addDisposable(disposable:DisposableItem) {
    __disposables.addDisposable(disposable);
  }

  public function removeDisposable(disposable:DisposableItem) {
    __disposables.removeDisposable(disposable);
  }

  public function dispose() {
    assert(__status != Rendering, 'Attempted to dispose a component while it was building');
    assert(__status != Disposing, 'Attempted to dispose a component that is already disposing');
    assert(__status != Disposed, 'Attempted to dispose a component that was already disposed');

    __status = Disposing;
    __invalidChildren = [];
    __disposables.dispose();
    __dispose();
    __slot = null;

    visitChildren(child -> {
      child.dispose();
      return true;
    });
    
    __status = Disposed;
  }
}
