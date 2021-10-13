package blok;

/**
  A ConcreteWidget is a widget that represents a Concrete item
  in a Blok platform (for example, in `blok.platform.dom`, the 
  ElementWidget and the TextWidget are both ConcreteWidgets).

  You should never use this class unless you're building a new
  platform.
**/
abstract class ConcreteWidget 
  extends Widget 
  implements ConcreteManager
{
  function getConcreteManager() {
    return this;
  }
}
