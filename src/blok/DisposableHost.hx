package blok;

interface DisposableHost {
	public function addDisposable(disposable:DisposableItem):Void;
	public function removeDisposable(disposable:DisposableItem):Void;
}
