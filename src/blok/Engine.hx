package blok;

import blok.core.Rendered;

@:nullSafety
interface Engine {
  public function initialize(component:Component):Rendered;
  public function update(component:Component):Rendered;
  public function remove(component:Component):Void;
  public function schedule(cb:()->Void):Void;
  public function getContext():Context;
  public function withNewContext():Engine;
}
