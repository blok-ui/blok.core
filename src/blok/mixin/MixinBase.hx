package blok.mixin;

import blok.debug.Debug;
import blok.core.*;
import blok.ui.*;

@:autoBuild(blok.mixin.MixinBuilder.build())
abstract class MixinBase<T> implements DisposableHost implements Disposable {
	final view:T;
	final disposables:DisposableCollection = new DisposableCollection();

	public function new(view) {
		assert(view is View);
		this.view = view;
	}

	abstract public function setup():Void;

	/**
		Access the underlying View instance as a View. This is useful if you
		need to get at underlying View api methods like `getParent` etc.
	**/
	public inline function unwrap():View {
		return cast this.view;
	}

	public function addDisposable(disposable:DisposableItem):Void {
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem):Void {
		disposables.removeDisposable(disposable);
	}

	public function dispose() {
		disposables.dispose();
	}
}
