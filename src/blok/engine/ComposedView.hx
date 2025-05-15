package blok.engine;

import blok.core.*;
import blok.signal.Computation;

typedef ComposedViewState<T:Node> = {
	public function render():Child;
	public function setup():Void;
	public function update(node:T):Void;
	public function dispose():Void;
}

enum ComposedViewRenderingMode {
	Normal;
	Hydrating;
}

enum ComposedViewStatus {
	Valid;
	Invalid;
	Rendering(mode:ComposedViewRenderingMode);
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

@:allow(blok)
class ComposedView<T:Node, State:ComposedViewState<T>> implements View {
	public final state:State;
	public final queue:ComposedViewValidationQueue<T, State>;

	final adaptor:Adaptor;
	final owner:Owner = new Owner();
	final render:Computation<Result<Node, Any>>;
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
		return child
			.insert(doRender(), cursor, hydrate)
			.always(() -> {
				Owner.capture(owner, {
					state.setup();
				});
			})
			.always(() -> status = Valid)
			.map(_ -> (this : View));
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		if (!this.node.matches(node)) return Error(ViewIncorrectNodeType(this, node));

		this.node = cast node;
		this.parent = parent;

		status = Rendering(Normal);

		state.update(this.node);

		return child
			.reconcile(doRender(), cursor)
			.map(_ -> (this : View))
			.always(() -> status = Valid);
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

		status = Rendering(Normal);
		return child
			.reconcile(doRender(), adaptor.siblings(this.firstPrimitive()))
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

	function doRender() {
		return switch render.peek() {
			case Ok(node):
				node;
			case Error(error):
				this
					.findAncestorOfType(BoundaryView)
					.inspect(boundary -> boundary.capture(this, error))
					.or(() -> throw error);
				Placeholder.node();
		}
	}
}
