package blok;

abstract class ConcreteWidget 
  extends Widget 
  implements ConcreteManager
{
  override function addChild(widget:Widget) {
    // Note: ConcreteManager expects that the new child widget has *not*
    //       been added yet, and thus MUST run first.
    addConcreteChild(widget);
    super.addChild(widget);
  }

  override function insertChildAt(pos:Int, widget:Widget) {
    // Note: ConcreteManager expects that the new child widget has *not*
    //       been added yet, and thus MUST run first.
    insertConcreteChildAt(pos, widget);
    super.insertChildAt(pos, widget);
  }

  override function removeChild(widget:Widget):Bool {
    // Note: ConcreteManager expects that the new child widget has *not*
    //       been removed yet, and thus MUST run first.
    if (widget != null && __children.has(widget)) {
      removeConcreteChild(widget);
    }
    return super.removeChild(widget);
  }

  override function moveChildTo(pos:Int, widget:Widget) {
    // Note: ConcreteManager expects that the new child widget has *not*
    //       been moved yet, and thus MUST run first.
    moveConcreteChildTo(pos, widget);
    super.moveChildTo(pos, widget);
  }

  function getConcreteManager() {
    return this;
  }
}
