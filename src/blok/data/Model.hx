package blok.data;

/**
	A class with reactive properties that can also be serialized into json
	(if you don't need this feature you can also use the `UnserializableModel`).
**/
@:autoBuild(blok.data.ModelBuilder.buildWithJsonSerializer())
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
