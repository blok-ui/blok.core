package blok;

abstract class ConcreteWidget 
  extends Widget 
  implements ConcreteManager
{
  function getConcreteManager() {
    return this;
  }
}
