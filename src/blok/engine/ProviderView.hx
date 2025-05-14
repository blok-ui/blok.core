package blok.engine;

class ProviderView<T:Providable> implements View {
	final adaptor:Adaptor;
	final child:ViewReconciler;

	var parent:Maybe<View>;
	var node:ProviderNode<T>;

	public function new(parent, node, adaptor) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.child = new ViewReconciler(this, adaptor);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function currentContext():T {
		return node.context;
	}

	public function match(contextId:Int) {
		return node.context.getContextId() == contextId;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		return child.insert(node.child, cursor, hydrate).map(_ -> (this : View));
	}

	public function update(parent:Maybe<View>, incoming:Node, cursor:Cursor):Result<View, ViewError> {
		if (!this.node.matches(node)) return Error(ViewIncorrectNodeType(this, node));

		var currentContext = node.context;
		var incomingProvider:ProviderNode<T> = cast incoming;

		if (currentContext != incomingProvider.context) {
			if (node.shared) {
				return Error(ViewError.ViewKitError(this, new Error(NotAcceptable, 'Shared providers should always have the same value')));
			}
			currentContext.dispose();
		}

		this.node = cast incoming;
		this.parent = parent;

		return child.reconcile(node.child, cursor).map(_ -> (this : View));
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		if (!node.shared) node.context.dispose();
		child.remove(cursor);
		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		child.get().inspect(view -> visitor(view));
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		child.get().inspect(view -> view.visitPrimitives(visitor));
	}
}
