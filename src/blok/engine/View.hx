package blok.engine;

@:using(View.ViewTools)
interface View {
	public function currentNode():Node;
	public function currentParent():Maybe<View>;
	public function insert(cursor:Cursor, ?hydrate:Bool):Result<View, ViewError>;
	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError>;
	public function remove(cursor:Cursor):Result<View, ViewError>;
	public function visitPrimitives(visitor:(primitive:Any) -> Bool):Void;
	public function visitChildren(visitor:(child:View) -> Bool):Void;
}

class ViewTools {
	public static function firstPrimitive(view:View):Any {
		var primitive = null;
		view.visitPrimitives(node -> {
			primitive = node;
			false;
		});
		return primitive;
	}

	public static function findAncestor(view:View, match:(ancestor:View) -> Bool):Maybe<View> {
		return view.currentParent().flatMap(parent -> if (match(parent)) {
			Some(parent);
		} else {
			parent.findAncestor(match);
		});
	}

	public static function findAncestorOfType<T:View>(view:View, kind:Class<T>):Maybe<T> {
		return view.currentParent().flatMap(parent -> switch (Std.downcast(parent, kind) : Null<T>) {
			case null: parent.findAncestorOfType(kind);
			case found: Some(cast found);
		});
	}

	public static function filterChildren(view:View, match:(child:View) -> Bool, recursive:Bool = false):Array<View> {
		var results:Array<View> = [];

		view.visitChildren(child -> {
			if (match(child)) results.push(child);

			if (recursive) {
				results = results.concat(child.filterChildren(match, true));
			}

			true;
		});

		return results;
	}

	public static function findChild(view:View, match:(child:View) -> Bool, recursive:Bool = false):Maybe<View> {
		var result:Null<View> = null;

		view.visitChildren(child -> {
			if (match(child)) {
				result = child;
				return false;
			}
			true;
		});

		return switch result {
			case null if (recursive):
				view.visitChildren(child -> switch child.findChild(match, true) {
					case Some(value):
						result = value;
						false;
					case None:
						true;
				});
				if (result == null) None else Some(result);
			case null:
				None;
			default:
				Some(result);
		}
	}

	public static function filterChildrenOfType<T:View>(view:View, kind:Class<T>, recursive:Bool = false):Array<T> {
		return cast view.filterChildren(child -> Std.isOfType(child, kind), recursive);
	}

	public static function findChildOfType<T:View>(view:View, kind:Class<T>, recursive:Bool = false):Maybe<T> {
		return cast view.findChild(child -> Std.isOfType(child, kind), recursive);
	}
}
