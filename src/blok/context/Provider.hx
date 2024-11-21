package blok.context;

import blok.context.Providable;
import blok.ui.*;

class Provider<T:Providable> extends Component {
	public static function compose(contexts:Array<Providable>) {
		return new VProvider(contexts);
	}

	public inline static function provide(context:Providable) {
		return new VProvider([context]);
	}

	@:attribute final context:T;
	@:children @:attribute final child:Child;

	var currentContext:Null<T> = null;

	function setup() {
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
		if (context != currentContext) {
			currentContext?.dispose();
			currentContext = context;
		}
		return child;
	}
}

abstract VProvider({
	public final contexts:Array<Providable>;
	public var child:Null<Child>;
}) {
	public inline function new(contexts) {
		this = {
			contexts: contexts,
			child: null
		};
	}

	public inline function provide(value) {
		this.contexts.push(value);
		return abstract;
	}

	public inline function child(child:Child) {
		this.child = child;
		return abstract;
	}

	@:to
	public function node():Child {
		var contexts = this.contexts.copy();
		var child = this.child;
		var context = contexts.shift();
		var component:VNode = Provider.node({
			context: context,
			child: child
		});

		while (contexts.length > 0) {
			var wrapped = component;
			context = contexts.shift();
			component = Provider.node({
				context: context,
				child: wrapped
			});
		}

		return component;
	}
}
