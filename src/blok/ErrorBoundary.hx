package blok;

import haxe.Exception;

using blok.BoundaryTools;

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
		return new VComponent(componentType, props, ErrorBoundary.new, key);
	}

	final controller:ReplaceableViewController;

	var status:ErrorBoundaryStatus = Ok;
	var child:Child;
	var fallback:(component:View, e:Exception) -> Child;

	public function new(node) {
		__node = node;
		controller = new ReplaceableViewController(this);
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
			status = Caught(component, object);
			controller.hide(() -> fallback(component, object));
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
		controller.setup(view);
		view.mount(getAdaptor(), this, __slot);
	}

	function __hydrate(cursor:Cursor) {
		var view = child.createView();
		controller.setup(view);
		view.hydrate(cursor, getAdaptor(), this, __slot);
	}

	function __update() {
		if (!updateProps()) return;
		controller.real()?.update(child);
		controller.show();
	}

	function __validate() {
		controller.show();
	}

	function __dispose() {
		controller.dispose();
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		controller.current().updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		return controller.current().getPrimitive();
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return node.type == componentType;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (controller.current() != null) visitor(controller.current());
	}
}
