package blok.engine;

import blok.core.*;
import blok.signal.Computation;

typedef ComposableViewState<T:Node> = {
	public function render():Child;
	public function setup():Void;
	public function update(node:T):Void;
}

@:allow(blok)
class ComposableView<T:Node, State:ComposableViewState<T>> implements View {
	public final state:State;
	public final queue:ComposedViewValidationQueue<T, State>;
	public var status(default, null):ViewStatus = Invalid;

	final adaptor:Adaptor;
	final disposables:DisposableCollection;
	final render:Computation<Result<Node, Any>>;
	final child:ViewReconciler;

	var parent:Maybe<View>;
	var node:T;

	public function new(parent, node, adaptor, state, ?disposables) {
		this.adaptor = adaptor;
		this.parent = parent;
		this.node = node;
		this.state = state;
		this.disposables = disposables ?? new DisposableCollection();
		this.queue = new ComposedViewValidationQueue(this);
		this.child = new ViewReconciler(this, adaptor);
		this.render = Owner.capture(this.disposables, {
			var isolate = new Isolate(state.render);
			Computation.persist(() -> switch status {
				case Disposing | Disposed:
					Ok(Placeholder.node());
				default:
					var node = try Ok(isolate() ?? Placeholder.node()) catch (e:Any) {
						isolate.cleanup();
						Error(e);
					}

					switch status {
						case Rendering(_):
						default: invalidate();
					}

					node;
			});
		});
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		status = Rendering(hydrate == true ? Hydrating : Normal);

		var result = doRender();

		return child
			.insert(result.node, cursor, hydrate)
			.always(() -> status = Valid)
			.always(() -> attemptToHandleError(result))
			.always(() -> {
				Owner.capture(disposables, {
					state.setup();
				});
			})
			.map(_ -> (this : View));
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		if (!this.node.matches(node)) return Error(IncorrectNodeType(this, node));

		this.node = cast node;
		this.parent = parent;

		status = Rendering(Normal);

		state.update(this.node);

		var result = doRender();

		return child
			.reconcile(result.node, cursor)
			.always(() -> status = Valid)
			.always(() -> attemptToHandleError(result))
			.map(_ -> (this : View));
	}

	public function invalidate() {
		if (status == Invalid) return;

		status = Invalid;

		switch this.findAncestorOfType(ComposableView) {
			case Some(parent):
				parent.queue.enqueue(cast this);
			case None:
				adaptor.schedule(() -> validate());
		}
	}

	public function validate():Result<View, ViewError> {
		if (status != Invalid) {
			queue.validate();
			if (status != Invalid) status = Valid;
			return Ok(this);
		}

		status = Rendering(Normal);

		var result = doRender();
		var cursor = adaptor.siblings(this.firstPrimitive());

		return child
			.reconcile(result.node, cursor)
			.always(() -> status = Valid)
			.always(() -> attemptToHandleError(result))
			.map(_ -> (this : View));
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		status = Disposing;

		disposables.dispose();
		child.remove(cursor);

		status = Disposed;

		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		child.get().inspect(child -> visitor(child));
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		child.get().inspect(child -> child.visitPrimitives(visitor));
	}

	function doRender():{node:Node, error:Maybe<Any>} {
		return switch render.peek() {
			case Ok(node):
				{node: node, error: None};
			case Error(error):
				{node: Placeholder.node(), error: Some(error)};
		}
	}

	inline function attemptToHandleError(result:{node:Node, error:Maybe<Any>}) {
		result.error.extract(if (Some(error)) this.sendErrorToBoundary(this, error));
	}

	public function addDisposable(disposable:DisposableItem) {
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables.removeDisposable(disposable);
	}
}

private class ComposedViewValidationQueue<T:Node, State:ComposableViewState<T>> {
	final view:ComposableView<T, State>;

	var pending:Array<ComposableView<Node, ComposableViewState<Node>>> = [];

	public function new(view) {
		this.view = view;
	}

	public function enqueue(child:ComposableView<Node, ComposableViewState<Node>>) {
		if (view.status == Invalid) return;
		if (pending.contains(child)) return;

		pending.push(child);

		switch view.findAncestorOfType(ComposableView) {
			case Some(parent):
				parent.queue.enqueue(cast view);
			case None:
				view.adaptor.schedule(() -> view.validate());
		}
	}

	public function validate() {
		if (pending.length == 0) return;
		var toValidate = pending.copy();
		pending = [];
		for (child in toValidate) child.validate();
	}
}
