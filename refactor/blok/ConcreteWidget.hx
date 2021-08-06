package blok;

abstract class ConcreteWidget 
  extends Widget 
  implements ConcreteManager
{
  override function addChild(widget:Widget) {
    super.addChild(widget);
    addConcreteChild(widget);
  }

  override function insertChildAt(pos:Int, widget:Widget) {
    super.insertChildAt(pos, widget);
    insertConcreteChildAt(pos, widget);
  }

  override function removeChild(widget:Widget):Bool {
    return if (super.removeChild(widget)) {
      removeConcreteChild(widget);
      true;
    } else false;
  }

  override function moveChildTo(pos:Int, widget:Widget) {
    super.moveChildTo(pos, widget);
    moveConcreteChildTo(pos, widget);
  }

  function getConcreteManager() {
    return this;
  }
}
