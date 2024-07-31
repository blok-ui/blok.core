package blok.ui;

import blok.adaptor.*;
import blok.core.*;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.signal.Observer;
import blok.signal.Signal;

using blok.adaptor.PrimitiveHostTools;

class Primitive extends View implements PrimitiveHost {
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

	var primitive:Null<Dynamic> = null;
	var children:Array<View> = [];

	public function new(node:VPrimitive) {
		tag = node.tag;
		type = node.type;
		__node = node;
	}

	function render() {
		var vn:VPrimitive = cast __node;
		return vn.children?.filter(n -> n != null) ?? [];
	}

	function observeAttributes() {
		function applyAttribute(name:String, oldValue:Any, value:Any) {
			getAdaptor().updatePrimitiveAttribute(getPrimitive(), name, oldValue, value, __renderMode == Hydrating);
		}

		var props = __node.getProps();
		var fields = Reflect.fields(props);

		for (name in updaters.keys()) {
			if (!fields.contains(name)) {
				updaters.get(name)?.dispose();
				updaters.remove(name);
			}
		}

		Owner.with(this, () -> for (name in fields) {
			var signal:ReadOnlySignal<Any> = Reflect.field(props, name);
			var updater = updaters.get(name);

			if (signal == null) signal = new Signal(null);

			if (updater == null) {
				updater = new PrimitivePropertyUpdater(name, signal, applyAttribute);
				updaters.set(name, updater);
			} else {
				updater.update(signal);
			}
		});
	}

	function __initialize() {
		primitive = createPrimitive();
		observeAttributes();

		var nodes = render();
		var previous:View = null;

		children = [for (i => node in nodes) {
			var child = node.createComponent();
			child.mount(getAdaptor(), this, createSlot(i, previous));
			previous = child;
			child;
		}];
		getAdaptor().insertPrimitive(primitive, __slot, () -> this.findNearestPrimitive());
	}

	function __hydrate(cursor:Cursor) {
		primitive = cursor.current();
		observeAttributes();

		var nodes = render();
		var localCursor = cursor.currentChildren();
		var previous:View = null;

		children = [for (i => node in nodes) {
			var child = node.createComponent();
			child.hydrate(localCursor, getAdaptor(), this, createSlot(i, previous));
			previous = child;
			child;
		}];

		assert(localCursor.current() == null);

		cursor.next();
	}

	function __update() {
		observeAttributes();
		children = diffChildren(this, children, render());
	}

	function __validate() {
		children = diffChildren(this, children, render());
	}

	function __dispose() {
		for (_ => updater in updaters) {
			updater.dispose();
		}
		updaters.clear();
		getAdaptor().removePrimitive(getPrimitive(), __slot);
	}

	function __updateSlot(oldSlot:Null<Slot>, newSlot:Null<Slot>) {
		getAdaptor().movePrimitive(getPrimitive(), oldSlot, newSlot, () -> this.findNearestPrimitive());
	}

	function createPrimitive() {
		return getAdaptor().createPrimitive(tag, {});
	}

	public function getPrimitive():Dynamic {
		assert(primitive != null);
		return primitive;
	}

	public function canBeUpdatedByNode(node:VNode):Bool {
		return type == node.type;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		for (child in children) if (!visitor(child)) return;
	}
}

class PrimitivePropertyUpdater<T> implements Disposable {
	final name:String;
	final changeSignal:Signal<ReadOnlySignal<T>>;
	final observer:Observer;
	final setAttribute:(name:String, oldValue:T, newValue:T) -> Void;

	var oldValue:Null<T> = null;

	public function new(name:String, propSignal:ReadOnlySignal<T>, setAttribute) {
		this.name = name;
		this.changeSignal = new Signal(propSignal);
		this.setAttribute = setAttribute;
		this.observer = new Observer(() -> {
			var signal = changeSignal();
			var value = signal();

			if (value == oldValue) return;

			setAttribute(name, oldValue, value);
			oldValue = value;
		});
	}

	public function update(newSignal:ReadOnlySignal<T>) {
		changeSignal.set(newSignal);
	}

	public function dispose() {
		observer.dispose();
		// @todo: Not 100% on needing this.
		// @todo: This seems to be setting the attribute to null,
		// not removing it (as intended). This can cause weird
		// things, like triggering a request to the url "null"
		// when used on elements with `src` or `href`. This is bad.
		setAttribute(name, oldValue, null);
	}
}
