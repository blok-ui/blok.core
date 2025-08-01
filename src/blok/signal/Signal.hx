package blok.signal;

import blok.signal.Computation;

@:forward
abstract Signal<T>(SignalObject<T>) to ReadOnlySignal<T> {
	@:from
	public static function of<T>(value:T):Signal<T> {
		return new Signal(value);
	}

	@:from
	@:deprecated('use `of` instead')
	public static function ofValue<T>(value:T):Signal<T> {
		return new Signal(value);
	}

	public inline function new(value, ?equal) {
		this = new SignalObject(value, equal);
	}

	@:op(a())
	public inline function get() {
		return this.get();
	}

	public inline function peek() {
		return this.peek();
	}

	public inline function map<R>(transform:(value:T) -> R):ReadOnlySignal<R> {
		return new Computation(() -> transform(get()));
	}

	public inline function readOnly():ReadOnlySignal<T> {
		return this;
	}
}

class SignalObject<T> {
	final node:ReactiveNode;
	final equal:(a:T, b:T) -> Bool;

	var value:T;

	public function new(value, ?equal) {
		this.value = value;
		this.equal = equal ?? (a, b) -> a == b;
		this.node = new ReactiveNode(Runtime.current());
	}

	public function get():T {
		node.accessed();
		return value;
	}

	public function peek():T {
		return value;
	}

	public function set(value:T) {
		if (equal(this.value, value)) return;

		this.value = value;

		node.version++;
		node.runtime.incrementEpoch();
		node.notify();
	}

	public function update(handler:(oldValue:T) -> T) {
		set(handler(value));
	}
}

class StaticSignalObject<T> {
	final value:T;

	public function new(value) {
		this.value = value;
	}

	public function get():T {
		return value;
	}

	public function peek():T {
		return value;
	}
}

typedef ReadOnlySignalObject<T> = {
	public function get():T;
	public function peek():T;
}

abstract ReadOnlySignal<T>(ReadOnlySignalObject<T>) from ReadOnlySignalObject<T> from SignalObject<T> from ComputationObject<T> {
	@:from
	public inline static function ofSignal<T>(signal:Signal<T>):ReadOnlySignal<T> {
		return signal;
	}

	@:from
	public inline static function ofComputation<T>(computation:Computation<T>):ReadOnlySignal<T> {
		return computation;
	}

	@:from
	public inline static function ofReadOnlySignal<T>(signal:ReadOnlySignal<T>):ReadOnlySignal<T> {
		return signal;
	}

	@:from
	public inline static function of<T>(value:T):ReadOnlySignal<T> {
		return new ReadOnlySignal(value);
	}

	@:from
	@:deprecated('use `of` instead')
	public inline static function ofValue<T>(value:T):ReadOnlySignal<T> {
		return new ReadOnlySignal(value);
	}

	public inline function new(value:T) {
		this = new StaticSignalObject(value);
	}

	public inline function map<R>(transform:(value:T) -> R):ReadOnlySignal<R> {
		return new Computation(() -> transform(get()));
	}

	@:op(a())
	public inline function get():T {
		return this.get();
	}

	public inline function peek() {
		return this.peek();
	}
}
