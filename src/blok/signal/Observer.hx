package blok.signal;

@:forward(dispose)
abstract Observer(ObserverObject) to DisposableItem to Disposable {
	public static function untrack(effect:() -> Void):Void {
		Runtime.current().untrack(effect);
	}

	public static function track(effect:() -> Void):Disposable {
		return new Observer(effect);
	}

	public inline function new(effect:() -> Void) {
		this = new ObserverObject(effect);
	}
}

class ObserverObject implements Disposable {
	var node:Null<ReactiveNode>;

	public function new(effect:() -> Void) {
		this.node = new ReactiveNode(Runtime.current(), node -> node.useAsCurrentConsumer(effect), {
			alwaysLive: true
		});
		node.useAsCurrentConsumer(effect);
		Owner.current()?.addDisposable(this);
	}

	public function dispose() {
		if (node == null) return;
		node.disconnect();
		node = null;
	}
}
