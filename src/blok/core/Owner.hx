package blok.core;

@:allow(blok)
class Owner implements DisposableHost implements Disposable {
	static var currentOwner:Null<DisposableHost> = null;

	public static function setCurrent(owner:DisposableHost) {
		var prev = currentOwner;
		currentOwner = owner;
		return prev;
	}

	public static function current() {
		return currentOwner;
	}

	public static function isInOwnershipContext() {
		return currentOwner != null;
	}

	public macro static function capture(owner, expr);

	@:deprecated('Use Owner.capture instead')
	public static function with<T>(owner:DisposableHost, scope:() -> T):T {
		var prev = setCurrent(owner);
		var value = try scope() catch (e) {
			setCurrent(prev);
			throw e;
		}
		setCurrent(prev);
		return value;
	}

	final disposables:DisposableCollection = new DisposableCollection();

	public function new() {}

	public function own<T>(scope:() -> T) {
		var prev = setCurrent(this);
		var value = try scope() catch (e) {
			setCurrent(prev);
			throw e;
		}
		setCurrent(prev);
		return value;
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
