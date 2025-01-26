package blok.data;

@:autoBuild(blok.data.ModelBuilder.buildWithoutJsonSerializer())
abstract class UnserializableModel implements Disposable implements DisposableHost {
	final disposables:DisposableCollection = new DisposableCollection();

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
