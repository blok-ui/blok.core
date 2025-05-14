package blok.engine;

class FragmentView implements View {
	final adaptor:Adaptor;

	var parent:Maybe<View>;
	var node:FragmentNode;
	var children:ViewListReconciler;

	public function new(parent, node, adaptor) {
		this.adaptor = adaptor;
		this.parent = parent;
		this.node = node;
		this.children = new ViewListReconciler(this, adaptor);
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		var nodes = node.children;
		if (nodes.length == 0) nodes = [new TextNode('')];

		this.children.reconcile(nodes, cursor, hydrate).orReturn();
		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;
		this.node = this.node
			.replaceWith(node)
			.mapError(node -> ViewError.ViewIncorrectNodeType(this, node))
			.orReturn();

		var nodes = this.node.children;
		if (nodes.length == 0) nodes = [new TextNode('')];

		children.reconcile(nodes, cursor).orReturn();

		return Ok(this);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		this.children.remove(cursor).orReturn();
		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		this.children.each(visitor);
	}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		children.each(child -> {
			child.visitPrimitives(visitor);
			true;
		});
	}
}
