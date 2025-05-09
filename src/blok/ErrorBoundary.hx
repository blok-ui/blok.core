package blok;

import haxe.Exception;

enum ErrorBoundaryStatus {
	Ok;
	Caught(view:View, e:Exception);
}

typedef ErrorBoundaryProps = {
	public final fallback:(view:View, e:Exception) -> Child;
	@:children public final child:Child;
}

class ErrorBoundary extends View {
	public static final componentType:UniqueId = new UniqueId();

	@:fromMarkup
	@:noUsing
	@:noCompletion
	public inline static function fromMarkup(props:ErrorBoundaryProps) {
		return node(props);
	}

	public static function node(props:ErrorBoundaryProps, ?key) {
		return new VComposableView(componentType, props, ErrorBoundary.new, key);
	}

	final replaceable:Replaceable;

	var child:Child;
	var fallback:(component:View, e:Exception) -> Child;

	public function new(node) {
		__node = node;
		replaceable = new Replaceable(this);
		updateProps();
	}

	override function __handleThrownObject(target:View, object:Any) {
		if (object is SuspenseException) switch findAncestorOfType(SuspenseBoundary) {
			case Some(boundary):
				boundary.__handleThrownObject(target, object);
				return;
			case None:
		}

		if (object is Exception) {
			replaceable.hide(() -> fallback(target, object));
			return;
		}

		super.__handleThrownObject(target, object);
	}

	function updateProps():Bool {
		var props:ErrorBoundaryProps = __node.getProps();
		var changed:Int = 0;

		if (child != props.child) {
			child = props.child;
			changed++;
		}

		if (fallback != props.fallback) {
			fallback = props.fallback;
			changed++;
		}

		return changed > 0;
	}

	function __initialize() {
		var view = child.createView();
		replaceable.setup(view);
		view.mount(getAdaptor(), this, __slot);
	}

	function __hydrate(cursor:Cursor) {
		var view = child.createView();
		replaceable.setup(view);
		view.hydrate(cursor, getAdaptor(), this, __slot);
	}

	function __update() {
		if (!updateProps()) return;
		replaceable.real()?.update(child);
		replaceable.show();
	}

	function __replace(other:View) {
		__initialize();
	}

	function __validate() {
		replaceable.show();
	}

	function __dispose() {
		replaceable.dispose();
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		replaceable.current().updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		return replaceable.current().getPrimitive();
	}

	public function canBeUpdatedByVNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function canReplaceOtherView(other:View):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (replaceable.current() != null) visitor(replaceable.current());
	}
}
