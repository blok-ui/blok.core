package blok.signal;

import blok.core.*;

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

	var owner:Owner;

	public function new(scope) {
		this.scope = scope;
		Owner.current()?.addDisposable(this);
	}

	public function get():T {
		cleanup();
		owner = new Owner();
		return owner.own(scope);
	}

	public function cleanup() {
		owner?.dispose();
		owner = null;
	}

	public function dispose() {
		owner?.dispose();
		owner = null;
	}
}
