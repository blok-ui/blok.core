package blok.data;

import blok.core.*;

@:autoBuild(blok.data.ModelBuilder.build())
abstract class Model implements Disposable implements DisposableHost {
	final disposables:DisposableCollection = new DisposableCollection();

	abstract public function toJson():Dynamic;

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
