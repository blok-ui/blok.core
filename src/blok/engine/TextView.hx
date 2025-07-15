package blok.engine;

import blok.core.*;

class TextView implements View {
	final adaptor:Adaptor;

	var disposables:Null<DisposableCollection>;
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
						.mapError(e -> ViewError.HydrationMismatch(this, '#text', current))
						.orReturn();
					cursor.next();
					return Ok(this);
				case None if (node.content != ''):
					return Error(NoNodeFoundDuringHydration(this, '#text'));
				case None:
					// An empty text node is a Placeholder; we can safely just insert it.
			}
		}

		primitive = adaptor.createTextPrimitive(node.content);
		cursor.insert(primitive)
			.mapError(e -> ViewError.InsertionFailed(this))
			.orReturn();

		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;
		this.node = this.node.replaceWith(node, this).orReturn();

		adaptor.updateTextPrimitive(primitive, this.node.content);

		cursor.insert(primitive)
			.mapError(e -> ViewError.UpdateFailed(this))
			.orReturn();

		return Ok(this);
	}

	public function rebuild():Result<View, ViewError> {
		adaptor.updateTextPrimitive(primitive, node.content);
		return Ok(this);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables?.dispose();
		cursor.remove(primitive)
			.mapError(e -> ViewError.RemovalFailed(this))
			.orReturn();
		primitive = null;
		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {}

	public function visitPrimitives(visitor:(primitive:Any) -> Bool) {
		if (primitive != null) visitor(primitive);
	}

	public function addDisposable(disposable:DisposableItem) {
		if (disposables == null) disposables = new DisposableCollection();
		disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		disposables?.removeDisposable(disposable);
	}
}
