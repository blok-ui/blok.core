package blok;

using Lambda;

final class DisposableCollection implements Disposable implements DisposableHost {
	var isDisposed:Bool = false;
	final disposables:List<Disposable> = new List();

	public function new() {}

	public function addDisposable(disposable:DisposableItem) {
		if (isDisposed) {
			disposable.dispose();
			return;
		}
		if (disposables.has(disposable)) return;
		disposables.push(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables.remove(disposable);
	}

	public function count() {
		return disposables.length;
	}

	public function dispose() {
		isDisposed = true;
		for (disposable in disposables) {
			disposables.remove(disposable);
			disposable.dispose();
		}
	}
}
