package blok;

import blok.debug.Debug;
import blok.signal.Observer;
import blok.signal.Signal;

class ElementPrimitiveView extends PrimitiveView {
	static final tagMappings:Map<String, UniqueId> = [];

	public static function getTypeForTag(tag:String) {
		var id = tagMappings.get(tag);
		if (id == null) {
			id = new UniqueId();
			tagMappings.set(tag, id);
		}
		return id;
	}

	final tag:String;
	final type:UniqueId;
	final updaters:Map<String, PrimitivePropertyUpdater<Any>> = [];

	var children:Array<View> = [];

	public function new(node:VPrimitiveView) {
		tag = node.tag;
		type = node.type;
		__node = node;
	}

	function resolveChildren() {
		var vn:VPrimitiveView = cast __node;
		return vn.children?.filter(n -> n != null) ?? [];
	}

	function observeAttributes() {
		var props = __node.getProps();
		var fields = Reflect.fields(props);

		for (name in updaters.keys()) {
			if (!fields.contains(name)) {
				updaters.get(name)?.dispose();
				updaters.remove(name);
			}
		}

		for (name in fields) {
			var signal:ReadOnlySignal<Any> = Reflect.field(props, name);
			var updater = updaters.get(name);

			if (signal == null) signal = new Signal(null);

			if (updater == null) {
				updater = new PrimitivePropertyUpdater(name, signal, (name:String, oldValue:Any, value:Any) -> {
					getAdaptor().updatePrimitiveAttribute(getPrimitive(), name, oldValue, value, viewIsHydrating());
				});
				updaters.set(name, updater);
			} else {
				updater.update(signal);
			}
		}
	}

	function __initialize() {
		primitive = createPrimitive();
		observeAttributes();

		var nodes = resolveChildren();
		var previous:View = null;

		children = [for (i => node in nodes) {
			var child = node.createView();
			child.mount(getAdaptor(), this, createSlot(i, previous));
			previous = child;
			child;
		}];
		getAdaptor().insertPrimitive(primitive, __slot);
	}

	function __hydrate(cursor:Cursor) {
		primitive = cursor.current();
		observeAttributes();

		var nodes = resolveChildren();
		var localCursor = cursor.currentChildren();
		var previous:View = null;

		children = [for (i => node in nodes) {
			var child = node.createView();
			child.hydrate(localCursor, getAdaptor(), this, createSlot(i, previous));
			previous = child;
			child;
		}];

		assert(localCursor.current() == null);

		cursor.next();
	}

	function __replace(other:View) {
		other.dispose();
		__initialize();
	}

	function __update() {
		observeAttributes();
		children = Differ.diffChildren(getAdaptor(), this, children, resolveChildren(), createSlot);
	}

	function __validate() {
		children = Differ.diffChildren(getAdaptor(), this, children, resolveChildren(), createSlot);
	}

	function __dispose() {
		for (_ => updater in updaters) {
			updater.dispose();
		}
		updaters.clear();
		getAdaptor().removePrimitive(getPrimitive(), __slot);
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		getAdaptor().movePrimitive(getPrimitive(), oldSlot, newSlot);
	}

	function createSlot(index:Int, previous:Null<View>) {
		return new Slot(this, index, previous);
	}

	function createPrimitive() {
		return getAdaptor().createPrimitive(tag, {});
	}

	public function getNearestPrimitive() {
		return getPrimitive();
	}

	public function canBeUpdatedByVNode(node:VNode):Bool {
		return type == node.type;
	}

	public function canReplaceOtherView(other:View):Bool {
		return false;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		for (child in children) if (!visitor(child)) return;
	}
}

class PrimitivePropertyUpdater<T> implements Disposable {
	final name:String;
	final changeSignal:Signal<ReadOnlySignal<T>>;
	final owner:Owner = new Owner();
	final setAttribute:(name:String, oldValue:T, newValue:T) -> Void;

	var oldValue:Null<T> = null;

	public function new(name:String, propSignal:ReadOnlySignal<T>, setAttribute) {
		this.name = name;
		this.setAttribute = setAttribute;
		Owner.capture(owner, {
			this.changeSignal = new Signal(propSignal);
			Observer.track(() -> {
				var signal = changeSignal();
				var value = signal();

				if (value == oldValue) return;

				setAttribute(name, oldValue, value);
				oldValue = value;
			});
		});
	}

	public function update(newSignal:ReadOnlySignal<T>) {
		changeSignal.set(newSignal);
	}

	public function dispose() {
		owner.dispose();
		// @todo: Not 100% on needing this.
		// @todo: This seems to be setting the attribute to null,
		// not removing it (as intended). This can cause weird
		// things, like triggering a request to the url "null"
		// when used on elements with `src` or `href`. This is bad.
		setAttribute(name, oldValue, null);
	}
}
