package blok.hook;

import blok.core.Disposable;
import blok.ui.View;

interface Hook extends Disposable {
	public function setup(view:View):Void;
}
