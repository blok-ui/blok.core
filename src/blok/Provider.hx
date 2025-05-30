package blok;

import blok.engine.*;

@:forward
@:forward.new
abstract Provider<T:Providable>(ProviderNode<T>) to Node to Child {
	@:fromMarkup
	public static function node<T:Providable>(props:{
		public final provide:T;
		@:children public final child:Child;
		public final ?shared:Bool;
		public final ?key:Key;
	}):Node {
		return new ProviderNode(props.provide, props.child, props.shared, props.key);
	}

	public inline static function provide(value:Providable) {
		return new ProviderFactory([{value: value, shared: false}]);
	}

	public inline static function share(value:Providable) {
		return new ProviderFactory([{value: value, shared: true}]);
	}
}

typedef ProvidableEntry = {
	public final value:Providable;
	public final shared:Bool;
}

abstract ProviderFactory({
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
		this.child = child;
		return abstract;
	}

	@:to
	public function node():Child {
		var contexts = this.contexts.copy();
		var child = this.child;
		var entry = contexts.shift();
		var component:Node = Provider.node({
			provide: entry.value,
			shared: entry.shared,
			child: child
		});

		while (contexts.length > 0) {
			var wrapped = component;
			entry = contexts.shift();
			component = Provider.node({
				provide: entry.value,
				shared: entry.shared,
				child: wrapped
			});
		}

		return component;
	}
}
