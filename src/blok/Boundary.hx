package blok;

import blok.View;

interface Boundary {
	public function handle(component:View, object:Any):Void;
}
