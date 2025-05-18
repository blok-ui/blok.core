package blok;

import blok.engine.*;
import blok.engine.BoundaryView;
import blok.signal.Resource;
import haxe.Exception;

typedef ErrorBoundaryProps = {
	public final fallback:(e:Exception) -> Child;
	@:children public final child:Child;
	public final ?key:Key;
}

class ErrorBoundary implements BoundaryNode<Exception> {
	@:fromMarkup
	@:noUsing
	public inline static function node(props:ErrorBoundaryProps) {
		return new ErrorBoundary(props.child, props.fallback, props.key);
	}

	public final fallback:(payload:Exception) -> Node;
	public final child:Node;
	public final key:Null<Key>;

	public function new(child, fallback, ?key) {
		this.child = child;
		this.fallback = fallback;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		return other is ErrorBoundary && other.key == key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new BoundaryView(parent, this, adaptor, {
			decode: (_, _, payload) -> {
				if (payload is ResourceException) return None;
				if (payload is ViewError) return switch (payload : ViewError) {
					case CausedException(_, exception):
						Some(exception);
					default:
						// @todo: Figure out how to handle this.
						None;
				}
				if (payload is Exception) return Some((payload : Exception));
				return None;
			},
			recover: (_, _, e) -> Future.immediate(Ignore)
		});
	}
}
