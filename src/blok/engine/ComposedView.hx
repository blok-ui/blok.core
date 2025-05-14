package blok.engine;

import blok.core.*;
import blok.signal.Computation;

typedef ComposedViewState<T:Node> = {
	public function render():Child;
	public function setup():Void;
	public function update(node:T):Void;
	public function dispose():Void;
}

enum ComposedViewStatus {
	Valid;
	Invalid;
	Rendering;
	Disposing;
	Disposed;
}

class ComposedViewValidationQueue<T:Node, State:ComposedViewState<T>> {
	final view:ComposedView<T, State>;

	var pending:Array<ComposedView<Node, ComposedViewState<Node>>> = [];

	public function new(view) {
		this.view = view;
	}

	public function enqueue(child:ComposedView<Node, ComposedViewState<Node>>) {
		if (view.status == Invalid) return;
		if (pending.contains(child)) return;

		pending.push(child);

		switch view.findAncestorOfType(ComposedView) {
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

// @todo: This is probably a good place to be handling errors returned from `insert`,
// `update` etc.

@:allow(blok.engine)
class ComposedView<T:Node, State:ComposedViewState<T>> implements View {
	public final state:State;
	public final queue:ComposedViewValidationQueue<T, State>;

	final adaptor:Adaptor;
	final owner:Owner = new Owner();
	final render:Computation<Node>;
	final child:ViewReconciler;

	var status:ComposedViewStatus = Valid;
	var parent:Maybe<View>;
	var node:T;
	var invalidQueue:Array<View> = [];

	public function new(parent, node, adaptor, state) {
		this.adaptor = adaptor;
		this.parent = parent;
		this.node = node;
		this.state = state;
		this.queue = new ComposedViewValidationQueue(this);
		this.child = new ViewReconciler(this, adaptor);
		this.render = Owner.capture(owner, {
			var isolate = new Isolate(state.render);
			Computation.persist(() -> switch status {
				case Disposing | Disposed:
					Placeholder.node();
				default:
					var node = try isolate() catch (e:Any) {
						isolate.cleanup();
						this
							.findAncestorOfType(BoundaryView)
							.inspect(boundary -> boundary.capture(this, e))
							.or(() -> throw e);
						null;
					}
					if (status != Rendering) invalidate();
					node ?? Placeholder.node();
			});
		});
	}

	public function invalidate() {
		if (status == Invalid) return;

		status = Invalid;

		switch this.findAncestorOfType(ComposedView) {
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

		status = Rendering;
		return child.reconcile(render.peek(), adaptor.siblings(this.firstPrimitive()))
			.map(_ -> (this : View))
			.always(() -> status = Valid);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		status = Rendering;

		function doInsert():Result<View, ViewError> {
			child.insert(render.peek(), cursor, hydrate).orReturn();

			Owner.capture(owner, {
				state.setup();
			});

			return Ok(this);
		}

		return doInsert().always(() -> status = Valid);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		if (!this.node.matches(node)) return Error(ViewIncorrectNodeType(this, node));

		this.node = cast node;
		this.parent = parent;

		status = Rendering;

		state.update(this.node);

		return child
			.reconcile(render.peek(), cursor)
			.map(_ -> (this : View))
			.always(() -> status = Valid);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		status = Disposing;

		owner.dispose();
		child.remove(cursor);
		state.dispose();

		status = Disposed;

		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		child.get().inspect(child -> visitor(child));
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		child.get().inspect(child -> child.visitPrimitives(visitor));
	}
}
