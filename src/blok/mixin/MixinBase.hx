package blok.mixin;

import blok.core.*;

@:autoBuild(blok.mixin.MixinBuilder.build())
abstract class MixinBase<T> implements DisposableHost implements Disposable {
	final view:T;
	final disposables:DisposableCollection = new DisposableCollection();

	public function new(view) {
		this.view = view;
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
