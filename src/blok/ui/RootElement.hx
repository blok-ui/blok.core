package blok.ui;

import blok.core.Debug;
import blok.state.Observable;

class RootElement extends ObjectElement {
  final onChange:Observable<RootElement>;
  var child:Null<Element> = null;
  var isScheduled:Bool = false;
  var invalidElements:Null<Array<Element>> = null;

  public function new(root:RootWidget) {
    super(root);
    platform = root.platform;
    parent = null;
    onChange = new Observable(this);
  }

  public inline function getObservable() {
    return onChange;
  }

  public function bootstrap() {
    mount(null);
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    super.mount(parent, slot);
    notify();
  }

  override function update(widget:Widget) {
    super.update(widget);
    notify();
  }

  override function hydrate(cursor:HydrationCursor, parent:Null<Element>, ?slot:Slot) {
    super.hydrate(cursor, parent, slot);
    notify();
  }

  override function rebuild() {
    super.rebuild();
    notify();
  }

  override function performSetup(parent:Null<Element>, ?slot:Slot) {
    Debug.assert(parent == null, 'Root elements should not have a parent');
    Debug.assert(platform != null, 'Root elements should get their platform from their widgets');
    this.slot = slot;
    status = Active;
  }

  override function createObject():Dynamic {
    return (cast widget:RootWidget).resolveRootObject(); 
  }

  public function scheduleAfterRebuild(cb:()->Void) {
    var disposable = onChange.next(_ -> cb());
    if (!isScheduled) scheduleRebuildInvalidElements();
    return disposable;
  }

  public function requestRebuild(child:Element) {
    if (child == this) {
      Debug.assert(lifecycle == Invalid);
      isScheduled = true;
      invalidElements = null;
      platform.schedule(() -> {
        rebuild();
        isScheduled = false;
      });
      return;
    }

    if (lifecycle == Invalid) return;
    Debug.assert(lifecycle == Valid);

    if (invalidElements == null) {
      invalidElements = [];
      scheduleRebuildInvalidElements();
    }

    if (invalidElements.contains(child)) return;
    invalidElements.push(child);
  }

  function scheduleRebuildInvalidElements() {
    if (isScheduled) return;
    isScheduled = true;
    platform.schedule(performRebuildInvalidElements);
  }

  function performRebuildInvalidElements() {
    isScheduled = false;
    
    if (invalidElements == null) {
      notify();
      return;
    }

    var elements = invalidElements.copy();
    invalidElements = null;
    for (el in elements) el.rebuild();
    notify();
  }

  function notify() {
    onChange.notify();
  }

  function performBuild(previousWidget:Null<Widget>) {
    if (previousWidget == null) {
      object = createObject();
    } else {
      if (previousWidget != widget) updateObject(previousWidget);
    }
    performBuildChild();
  }

  function performHydrate(cursor:HydrationCursor) {
    object = cursor.current();
    var objects = cursor.currentChildren();
    child = hydrateElementForWidget(objects, (cast widget:RootWidget).child, slot);
    cursor.next();
    Debug.assert(objects.current() == null);
  }

  function performBuildChild() {
    child = updateChild(child, (cast widget:RootWidget).child, slot);
  }
  
  function visitChildren(visitor:ElementVisitor) {
    if (child != null) visitor.visit(child);
  }
}
