package blok.engine;

class TextView implements View {
	final adaptor:Adaptor;

	var primitive:Any = null;
	var parent:Maybe<View>;
	var node:TextNode;

	public function new(parent, node, adaptor) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
	}

	public function currentNode():Node {
		return node;
	}

	public function currentParent():Maybe<View> {
		return parent;
	}

	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError> {
		if (hydrate == true) {
			switch cursor.current() {
				case Some(current):
					primitive = adaptor
						.checkText(current)
						.mapError(e -> ViewError.ViewHydrationMismatch(this, '#text', current))
						.orReturn();
					cursor.next();
					return Ok(this);
				case None:
					return Error(ViewHydrationNoNode(this, '#text'));
			}
		}

		primitive = adaptor.createTextPrimitive(node.content);
		cursor.insert(primitive)
			.mapError(e -> ViewError.ViewInsertionFailed(this))
			.orReturn();

		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;
		this.node = this.node
			.replaceWith(node)
			.mapError(node -> ViewError.ViewIncorrectNodeType(this, node))
			.orReturn();

		adaptor.updateTextPrimitive(primitive, this.node.content);

		cursor.insert(primitive)
			.mapError(e -> ViewError.ViewInsertionFailed(this))
			.orReturn();

		return Ok(this);
	}

	public function rebuild():Result<View, ViewError> {
		adaptor.updateTextPrimitive(primitive, node.content);
		return Ok(this);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		cursor.remove(primitive)
			.mapError(e -> ViewError.ViewInsertionFailed(this))
			.orReturn();
		primitive = null;
		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		if (primitive != null) visitor(primitive);
	}
}
