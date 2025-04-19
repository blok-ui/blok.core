package blok;

import blok.engine.*;
import haxe.Exception;

using blok.engine.BoundaryTools;

enum ErrorBoundaryStatus {
	Ok;
	Caught(component:View, e:Exception);
}

typedef ErrorBoundaryProps = {
	public final fallback:(component:View, e:Exception) -> Child;
	@:children public final child:Child;
}

class ErrorBoundary extends View implements Boundary {
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

	public function handle(component:View, object:Any) {
		if (object is SuspenseException) switch findAncestorOfType(SuspenseBoundary) {
			case Some(boundary):
				boundary.handle(component, object);
				return;
			case None:
		}

		if (object is Exception) {
			replaceable.hide(() -> fallback(component, object));
			return;
		}

		this.tryToHandleWithBoundary(object);
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

	public function canBeUpdatedByNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (replaceable.current() != null) visitor(replaceable.current());
	}
}
