package blok;

import blok.engine.*;
import blok.engine.BoundaryView;
import blok.signal.Resource;

using Lambda;

typedef SuspenseBoundaryProps = {
	@:children public final child:Child;

	/**
		Fallback to display while the component is suspended.
	**/
	public final fallback:() -> Child;

	/**
		A callback the fires when *all* suspensions inside
		this Boundary are completed. It will also run if the component is
		mounted and no suspensions occur.
	**/
	public var ?onComplete:() -> Void;

	/**
		Called when the Boundary is suspended. If more suspensions
		occur while the SuspenseBoundary is already suspended, this
		callback will *not* be called again.
	**/
	public var ?onSuspended:() -> Void;

	public var ?key:Key;
}

class SuspenseBoundary implements BoundaryNode<ResourceException> {
	@:fromMarkup
	@:noUsing
	public static function node(props:SuspenseBoundaryProps) {
		return new SuspenseBoundary(
			props.child,
			props.fallback,
			props.onComplete,
			props.onSuspended,
			props.key
		);
	}

	public final key:Null<Key>;
	public final child:Node;
	public final fallback:(error:ResourceException) -> Node;
	public final onComplete:Null<() -> Void>;
	public final onSuspended:Null<() -> Void>;

	public function new(child, fallback:() -> Node, ?onComplete, ?onSuspended, ?key) {
		this.child = child;
		this.fallback = _ -> fallback();
		this.onComplete = onComplete;
		this.onSuspended = onSuspended;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		return other is SuspenseBoundary && other.key == key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return new BoundaryView(parent, this, adaptor, {
			onStatusChanged: (boundary, status) -> {
				var node = boundary.currentBoundaryNode();
				switch status {
					case CaughtError:
						if (node?.onSuspended != null) {
							node.onSuspended();
						}
						SuspenseBoundaryContext
							.maybeFrom(boundary)
							.inspect(context -> context.add(boundary));
					case TouchedError:
						SuspenseBoundaryContext
							.maybeFrom(boundary)
							.inspect(context -> context.remove(boundary));
					case RecoveredFromError | InitializedWithoutError:
						if (node?.onComplete != null) {
							node.onComplete();
						}
						SuspenseBoundaryContext
							.maybeFrom(boundary)
							.inspect(context -> context.remove(boundary));
					case FailedToRecoverFromError:
						SuspenseBoundaryContext
							.maybeFrom(boundary)
							.inspect(context -> context.remove(boundary));
				}
			},
			onRemoval: boundary -> {
				SuspenseBoundaryContext
					.maybeFrom(boundary)
					.inspect(context -> context.remove(boundary));
			},
			decode: (boundary, target, error) -> {
				if (error is ResourceException) {
					return Some(cast error);
				}
				return None;
			},
			recover: (boundary, target, resource) -> {
				return resource.task
					.then(_ -> Recovered)
					.recover(e -> Future.immediate(Failed(e)));
			}
		});
	}
}
