package blok;

// @todo: Decide if manager hooks should run before or after widgets
//        are added to their parent. Right now, they run *before*
interface ConcreteManager extends Disposable {
  public function toConcrete():Array<Dynamic>;
  public function getFirstConcreteChild():Dynamic;
  public function getLastConcreteChild():Dynamic;
  public function addConcreteChild(child:Widget):Void;
  public function insertConcreteChildAt(pos:Int, child:Widget):Void;
  public function moveConcreteChildTo(pos:Int, child:Widget):Void;
  public function removeConcreteChild(child:Widget):Void;
}
