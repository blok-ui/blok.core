package blok.boundary;

import blok.ui.View;

interface Boundary {
	public function handle(component:View, object:Any):Void;
}
