package blok.engine;

import blok.core.Disposable;

using Lambda;

enum BoundaryStatus<T> {
	Active;
	Recovering(links:Array<BoundaryLink<T>>);
}

enum BoundaryRecovery {
	Recovered;
	Ignore;
	Failed(e:Error);
}

enum BoundaryStatusChanged {
	Initialized;
	CapturedPayload;
	RecoveredFromCapture;
	FailedToRecover;
}

typedef BoundaryViewState<T, N:BoundaryNode<T>> = {
	public final ?onStatusChanged:(boundary:BoundaryView<T, N>, status:BoundaryStatusChanged) -> Void;
	public final ?onRemoval:(boundary:BoundaryView<T, N>) -> Void;

	public function decode(boundary:BoundaryView<T, N>, target:View, payload:Any):Maybe<T>;
	public function recover(boundary:BoundaryView<T, N>, target:View, payload:T):Future<BoundaryRecovery>;
}

class BoundaryView<T, N:BoundaryNode<T>> implements View {
	final adaptor:Adaptor;
	final placeholder:ViewReconciler;
	final child:ViewReconciler;
	final state:BoundaryViewState<T, N>;
	final marker:View;

	var parent:Maybe<View>;
	var node:N;
	var status:BoundaryStatus<T> = Active;

	public function new(parent, node, adaptor, state) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.state = state;
		this.marker = new TextNode('').createView(Some(this), adaptor);
		this.placeholder = new ViewReconciler(this, adaptor);
		this.child = new ViewReconciler(this, adaptor);
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
			case Some(value):
				showPlaceholder(target, payload).orThrow();
			case None:
				bubblePayloadUpwards(target, payload);
		}
	}

	public function bubblePayloadUpwards(target:View, payload:Any) {
		this
			.findAncestorOfType(BoundaryView)
			.inspect(boundary -> boundary.capture(target, payload))
			.or(() -> throw payload);
	}

	public function showPlaceholder(target:View, payload:T):Result<View, ViewError> {
		function createLink() {
			return state.recover(this, target, payload).handle(result -> switch result {
				case Recovered:
					switch status {
						case Recovering(links):
							var recoveredLinks = links.filter(link -> if (link.payload == payload) {
								link.dispose();
								false;
							} else true);
							status = Recovering(recoveredLinks);
							if (recoveredLinks.length == 0) {
								adaptor.scheduleEffect(() -> {
									adaptor.schedule(() -> switch showChild() {
										case Ok(_):
										case Error(error):
											bubblePayloadUpwards(this, error);
									});
								});
							}
						case Active:
					}
				case Ignore:
				case Failed(e):
					if (state.onStatusChanged != null) {
						state.onStatusChanged(this, FailedToRecover);
					}
					bubblePayloadUpwards(target, e);
			});
		}

		switch status {
			case Recovering(links) if (links.exists(link -> link.payload == payload)):
				return Ok(this);
			case Recovering(links):
				status = Recovering([new BoundaryLink(payload, createLink())].concat(links));
				return Ok(this);
			case Active:
				status = Recovering([new BoundaryLink(payload, createLink())]);

				if (state.onStatusChanged != null) {
					state.onStatusChanged(this, CapturedPayload);
				}

				var child = switch this.child.get() {
					case None: return Error(ViewKitError(this, new Error(NotFound, 'No child view found')));
					case Some(view): view;
				}

				// Note: doing this as it ensures all child components will have
				// had a chance to render before we try to remove them. This works,
				// but I'm a little uncomfortable about it. I feel like this might lead to
				// race conditions at some point.
				adaptor.scheduleEffect(() -> {
					placeholder
						.insert(node.fallback(payload), adaptor.siblings(marker.firstPrimitive()))
						.orThrow();

					var primitive = child.firstPrimitive();

					if (primitive != null) {
						var cursor = adaptor.siblings(primitive);
						child.visitPrimitives(primitive -> {
							cursor.detach(primitive);
							true;
						});
					}
				});

				return Ok(this);
		}
	}

	public function showChild():Result<View, ViewError> {
		switch status {
			case Recovering(links) if (links.length == 0):
				status = Active;

				var cursor = adaptor.siblings(marker.firstPrimitive());

				placeholder.remove(cursor);

				var child = switch this.child.get() {
					case None: return Error(ViewKitError(this, new Error(NotFound, 'No child view found')));
					case Some(view): view;
				}

				child.visitPrimitives(primitive -> {
					cursor.insert(primitive);
					true;
				});

				if (state.onStatusChanged != null) {
					adaptor.scheduleEffect(() -> {
						if (status == Active) state.onStatusChanged(this, RecoveredFromCapture);
					});
				}

				return Ok(this);
			default:
				return Ok(this);
		}
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		marker.insert(cursor, false);

		cursor = adaptor.siblings(marker.firstPrimitive());
		child.insert(node.child, cursor, hydrate).orReturn();

		if (status == Active && state.onStatusChanged != null) {
			adaptor.scheduleEffect(() -> {
				if (status == Active) state.onStatusChanged(this, Initialized);
			});
		}

		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.node = cast(this.node : Node).replaceWith(node)
			.mapError(_ -> ViewError.ViewIncorrectNodeType(this, node))
			.orReturn();

		marker.update(Some(this), new TextNode(''), cursor).orReturn();
		cursor = adaptor.siblings(marker.firstPrimitive());

		switch status {
			case Recovering(links) if (links.length > 0):
				placeholder.reconcile(this.node.fallback(links[0].payload), cursor).orReturn();
			default:
				child.reconcile(this.node.child, cursor).orReturn();
		}

		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		switch status {
			case Recovering(_): placeholder.get().inspect(child -> visitor(child));
			case Active: child.get().inspect(child -> visitor(child));
		}
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		switch status {
			case Recovering(_): placeholder.get().inspect(child -> child.visitPrimitives(visitor));
			case Active: child.get().inspect(child -> child.visitPrimitives(visitor));
		}
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		switch status {
			case Recovering(links):
				for (link in links) link.dispose();
			default:
		}

		status = Active;

		if (state.onRemoval != null) {
			state.onRemoval(this);
		}

		marker.remove(cursor).orReturn();
		placeholder.remove(cursor).orReturn();
		child.remove(cursor).orReturn();

		return Ok(this);
	}
}

class BoundaryLink<T> implements Disposable {
	public final payload:T;

	final link:Null<Cancellable> = null;

	public function new(payload, link) {
		this.payload = payload;
		this.link = link;
	}

	public function dispose() {
		link.cancel();
	}
}
