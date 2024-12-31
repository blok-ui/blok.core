package blok;

import blok.debug.Debug;
import blok.Providable;

class Provider<T:Providable> extends Component {
	public inline static function provide(value:Providable) {
		return new VProvider([{value: value, shared: false}]);
	}

	public inline static function share(value:Providable) {
		return new VProvider([{value: value, shared: true}]);
	}

	@:attribute final context:T;
	@:attribute final shared:Bool = false;
	@:children @:attribute final child:Child;

	var currentContext:Null<T> = null;

	function setup() {
		if (shared) return;

		addDisposable(() -> {
			currentContext?.dispose();
			currentContext = null;
		});
	}

	public function match(contextId:Int):Bool {
		return context?.getContextId() == contextId;
	}

	public function getContext():Maybe<T> {
		return context != null ? Some(context) : None;
	}

	function render() {
		if (shared) {
			if (currentContext == null) currentContext = context;

			assert(currentContext == context, 'Shared providers should always have the same value');

			return child;
		}

		if (context != currentContext) {
			currentContext?.dispose();
			currentContext = context;
		}

		return child;
	}
}

typedef ProvidableEntry = {
	public final value:Providable;
	public final shared:Bool;
}

abstract VProvider({
	public final contexts:Array<ProvidableEntry>;
	public var child:Null<Child>;
}) {
	public inline function new(contexts) {
		this = {
			contexts: contexts,
			child: null
		};
	}

	public inline function provide(value) {
		this.contexts.push({value: value, shared: false});
		return abstract;
	}

	public inline function share(value) {
		this.contexts.push({value: value, shared: true});
		return abstract;
	}

	public inline function child(child:Child) {
		assert(this.child == null, 'Only one child is allowed');

		this.child = child;
		return abstract;
	}

	@:to
	public function node():Child {
		var contexts = this.contexts.copy();
		var child = this.child;
		var entry = contexts.shift();
		var component:VNode = Provider.node({
			context: entry.value,
			shared: entry.shared,
			child: child
		});

		while (contexts.length > 0) {
			var wrapped = component;
			entry = contexts.shift();
			component = Provider.node({
				context: entry.value,
				shared: entry.shared,
				child: wrapped
			});
		}

		return component;
	}
}
