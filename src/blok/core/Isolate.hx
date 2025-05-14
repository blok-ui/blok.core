package blok.core;

import blok.debug.Debug;

@:forward
abstract Isolate<T>(IsolateImpl<T>) to Disposable to DisposableItem {
	@:from
	public static inline function ofFunction<T>(scope:() -> T) {
		return new Isolate(scope);
	}

	public inline function new(scope) {
		this = new IsolateImpl(scope);
	}

	@:op(a())
	public inline function get():T {
		return this.get();
	}
}

class IsolateImpl<T> implements Disposable {
	final scope:() -> T;

	var owner:Null<Owner>;

	public function new(scope) {
		this.scope = scope;
		Owner.current()?.addDisposable(this);
	}

	public function get():T {
		cleanup();
		assert(owner != null);
		return owner.own(scope);
	}

	public function cleanup() {
		if (owner == null) {
			owner = new Owner();
			return;
		}

		var count = owner.disposables.count();

		if (count == 0) {
			return;
		}

		#if debug
		warn(
			'Captured ${count} disposables while running an Isolate -- try to get this down to 0 for best performance.'

		);
		#end

		owner.dispose();
		owner = new Owner();
	}

	public function dispose() {
		owner?.dispose();
		owner = null;
	}
}
