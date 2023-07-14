package blok.boundary;

import blok.ui.ComponentBase;

interface Boundary {
  public function handle(component:ComponentBase, object:Any):Void;
}
