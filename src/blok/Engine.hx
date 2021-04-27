package blok;

import blok.core.Rendered;

@:nullSafety
interface Engine {
  public function initialize(component:Component):Rendered;
  public function update(component:Component):Rendered;
  public function schedule(cb:()->Void):Void;
}
