package blok;

/**
  ConcreteManagers are used by Blok platforms to take Blok's widget tree
  and apply them to whatever the platform needs (such as, for example, the
  DOM). You should never have to use this class unless you're building
  a platform.
**/
interface ConcreteManager extends Disposable {
  public function toConcrete():Concrete;
  public function addConcreteChild(child:Widget):Void;
  public function insertConcreteChildAt(pos:Int, child:Widget):Void;
  public function moveConcreteChildTo(pos:Int, child:Widget):Void;
  public function removeConcreteChild(child:Widget):Void;
}
