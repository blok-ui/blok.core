package blok.engine;

import blok.engine.BoundaryNode;
import blok.core.*;

using Lambda;

enum BoundaryStatus<T, N:BoundaryNode<T>> {
	Active;
	Touched;
	Recovering(links:Array<BoundaryLink<T, N>>);
}

enum BoundaryRecovery {
	Recovered;
	Ignore;
	Failed(e:Error);
}

enum BoundaryStatusChanged {
	Initialized;
	CapturedPayload;
	TouchedPayload;
	RecoveredFromCapture;
	FailedToRecover;
}

typedef BoundaryViewState<T, N:BoundaryNode<T>> = {
	public final ?onStatusChanged:(boundary:BoundaryView<T, N>, status:BoundaryStatusChanged) -> Void;
	public final ?onRemoval:(boundary:BoundaryView<T, N>) -> Void;

	public function decode(boundary:BoundaryView<T, N>, target:View, payload:Any):Maybe<T>;
	public function recover(boundary:BoundaryView<T, N>, target:View, payload:T):Future<BoundaryRecovery>;
}

// @todo: We should track view status on this view to ensure we don't try updating when it's
// disposed/disposing.
class BoundaryView<T, N:BoundaryNode<T>> implements View implements Boundary {
	final adaptor:Adaptor;
	final placeholder:ViewReconciler;
	final child:ViewReconciler;
	final state:BoundaryViewState<T, N>;
	final marker:View;
	final container:Any;
	final disposables:DisposableCollection = new DisposableCollection();

	var parent:Maybe<View>;
	var node:N;
	var boundaryStatus:BoundaryStatus<T, N> = Active;

	public function new(parent, node, adaptor, state) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.state = state;
		this.marker = Placeholder.node().createView(Some(this), adaptor);
		this.placeholder = new ViewReconciler(this, adaptor);
		this.child = new ViewReconciler(this, adaptor);
		this.container = adaptor.createContainerPrimitive();
	}

	public function currentBoundaryNode():N {
		return node;
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function capture(target:View, payload:Any):Void {
		switch state.decode(this, target, payload) {
			case Some(decoded):
				showPlaceholder(target, decoded).orThrow();
			case None:
				bubblePayloadUpwards(target, payload);
		}
	}

	public function bubblePayloadUpwards(target:View, payload:Any) {
		boundaryStatus = Touched;

		if (state.onStatusChanged != null) {
			adaptor.scheduleEffect(() -> {
				state.onStatusChanged(this, TouchedPayload);
			});
		}

		this.captureWithBoundary(target, payload);
	}

	function createLink(target, payload) {
		var link = state.recover(this, target, payload).handle(result -> switch result {
			case Recovered:
				switch boundaryStatus {
					case Recovering(links):
						var recoveredLinks = links.filter(link -> if (link.payload == payload) {
							link.cancel();
							false;
						} else true);
						boundaryStatus = Recovering(recoveredLinks);
						if (recoveredLinks.length == 0) scheduleShowChild();
					case Active | Touched:
				}
			case Ignore:
			case Failed(e):
				if (state.onStatusChanged != null) {
					adaptor.scheduleEffect(() -> {
						state.onStatusChanged(this, FailedToRecover);
					});
				}
				bubblePayloadUpwards(target, e);
		});

		return new BoundaryLink(target, this, payload, link);
	}

	public function dissolveLink(target:BoundaryLink<T, N>) {
		switch boundaryStatus {
			case Recovering(links):
				var newLinks = links.filter(link -> link != target);
				boundaryStatus = Recovering(newLinks);
				if (newLinks.length == 0) scheduleShowChild();
			default:
		}
	}

	function scheduleShowChild() {
		adaptor.scheduleEffect(() -> {
			adaptor.schedule(() -> switch showChild() {
				case Ok(_):
				case Error(error):
					bubblePayloadUpwards(this, error);
			});
		});
	}

	public function showPlaceholder(target:View, payload:T):Result<View, ViewError> {
		switch boundaryStatus {
			case Recovering(links) if (links.exists(link -> link.payload == payload)):
				return Ok(this);
			case Recovering(links):
				boundaryStatus = Recovering([createLink(target, payload)].concat(links));
				return Ok(this);
			case Active | Touched:
				boundaryStatus = Recovering([createLink(target, payload)]);

				if (state.onStatusChanged != null) {
					state.onStatusChanged(this, CapturedPayload);
				}

				var child = switch this.child.get() {
					case None: return Error(CausedException(this, new Error(NotFound, 'No child view found')));
					case Some(view): view;
				}
				var fallback = try node.fallback(payload) catch (e) {
					return Error(CausedException(this, e));
				}

				placeholder
					.insert(fallback, adaptor.siblings(marker.firstPrimitive()))
					.orThrow();

				var cursor = adaptor.children(container);
				child.visitPrimitives(primitive -> {
					cursor.insert(primitive);
					true;
				});

				return Ok(this);
		}
	}

	public function showChild():Result<View, ViewError> {
		switch boundaryStatus {
			case Recovering(links) if (links.length == 0):
				boundaryStatus = Active;

				var child = switch this.child.get() {
					case None: return Error(CausedException(this, new Error(NotFound, 'No child view found')));
					case Some(view): view;
				}

				adaptor.scheduleEffect(() -> {
					if (boundaryStatus == Active) {
						var cursor = adaptor.siblings(marker.firstPrimitive());
						placeholder.remove(cursor);

						child.visitPrimitives(primitive -> {
							cursor.insert(primitive);
							true;
						});

						if (state.onStatusChanged != null) state.onStatusChanged(this, RecoveredFromCapture);
					}
				});

				return Ok(this);
			default:
				return Ok(this);
		}
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		marker.insert(cursor, false);

		child.insert(node.child, cursor, hydrate)
			.inspectError(error -> capture(child.get().unwrap(), error));

		if (boundaryStatus == Active && state.onStatusChanged != null) {
			adaptor.scheduleEffect(() -> {
				if (boundaryStatus == Active) state.onStatusChanged(this, Initialized);
			});
		}

		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.node = Node.NodeTools.replaceWith(this.node, node)
			.mapError(_ -> ViewError.IncorrectNodeType(this, node))
			.orReturn();

		boundaryStatus.extract(if (Recovering(links)) {
			for (link in links) link.cancel();
			placeholder.remove(cursor);
			boundaryStatus = Active;
		});

		marker.update(Some(this), Placeholder.node(), cursor).orReturn();
		cursor = adaptor.siblings(marker.firstPrimitive());

		child.reconcile(this.node.child, cursor)
			.inspectError(error -> capture(child.get().unwrap(), error));

		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		switch boundaryStatus {
			case Recovering(_): placeholder.get().inspect(child -> visitor(child));
			case Active | Touched: child.get().inspect(child -> visitor(child));
		}
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		marker.visitPrimitives(visitor);
		switch boundaryStatus {
			case Recovering(_):
				placeholder.get().inspect(child -> child.visitPrimitives(visitor));
			case Active | Touched:
				child.get().inspect(child -> child.visitPrimitives(visitor));
		}
	}

	public function addDisposable(disposable:DisposableItem) {
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables.removeDisposable(disposable);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables.dispose();

		switch boundaryStatus {
			case Recovering(links):
				for (link in links) link.cancel();
			default:
		}

		boundaryStatus = Active;

		if (state.onRemoval != null) {
			state.onRemoval(this);
		}

		adaptor.removePrimitive(container);
		marker.remove(cursor).orReturn();
		placeholder.remove(cursor).orReturn();
		child.remove(cursor).orReturn();

		return Ok(this);
	}
}

private class BoundaryLink<T, N:BoundaryNode<T>> implements Disposable {
	public final view:View;
	public final payload:T;

	final boundary:BoundaryView<T, N>;
	final link:Cancellable;

	public function new(view, boundary, payload, link) {
		this.view = view;
		this.boundary = boundary;
		this.payload = payload;
		this.link = link;
		view.addDisposable(this);
	}

	public function cancel() {
		view.removeDisposable(this);
		dispose();
	}

	public function dispose() {
		boundary.dissolveLink(this);
		link.cancel();
	}
}
