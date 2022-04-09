package blok.ui;

import blok.core.Debug;

class RootElement extends ObjectElement {
  var child:Null<Element> = null;
  var effects:Null<Effects> = null;
  var isScheduled:Bool = false;

  public function new(root:RootWidget) {
    super(root);
    platform = root.platform;
    rootElement = this;
    parent = null;
  }

  public function bootstrap() {
    mount(null);
  }

  override function mount(parent:Null<Element>, ?slot:Slot) {
    super.mount(parent, slot);
    dispatchEffects();
  }

  override function hydrate(cursor:HydrationCursor, parent:Null<Element>, ?slot:Slot) {
    super.hydrate(cursor, parent, slot);
    dispatchEffects();
  }

  override function createObject():Dynamic {
    return (cast widget:RootWidget).resolveRootObject(); 
  }

  override function performSetup(parent:Null<Element>, ?slot:Slot) {
    Debug.assert(parent == null, 'Root elements should not have a parent');
    Debug.assert(platform != null, 'Root elements should get their platform from their widgets');
    this.slot = slot;
    status = Active;
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

  function scheduleRebuild() {
    if (isScheduled) return;
    isScheduled = true;
    platform.schedule(validate);
  }

  override function invalidate() {
    Debug.assert(status == Active);
    Debug.assert(lifecycle == Valid);

    lifecycle = Invalid;
    scheduleRebuild();
  }

  override function validate() {
    Debug.assert(lifecycle != Building);
    isScheduled = false;

    switch lifecycle {
      case Invalid:
        invalidChildren = null;
        rebuild();

        Debug.assert(lifecycle == Valid);
        dispatchEffects();
      case Valid:
        if (invalidChildren == null) return;
        var pending = invalidChildren.copy();
        invalidChildren = null;
        for (child in pending) child.validate();
        
        dispatchEffects();
      default:
    }
  }

  override function enqueueChildElementForUpdate(child:Element) {
    if (invalidChildren == null) invalidChildren = [];
    if (!invalidChildren.contains(child)) invalidChildren.push(child);
    scheduleRebuild();
  }

  public function getEffects() {
    if (effects == null) effects = new Effects();
    return effects;
  }

  function dispatchEffects() {
    if (effects == null) return;
    var lastEffects = effects;
    effects = null;
    lastEffects.dispatch();
  }
}
