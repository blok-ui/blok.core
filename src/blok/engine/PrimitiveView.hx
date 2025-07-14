package blok.engine;

import blok.core.*;
import blok.signal.*;
import blok.signal.Signal;

class PrimitiveView<Attrs:{}> implements View {
	final adaptor:Adaptor;
	final attributes:PrimitiveAttributes<Attrs>;

	var disposables:Null<DisposableCollection> = null;
	var parent:Maybe<View>;
	var node:PrimitiveNode<Attrs>;
	var primitive:Any = null;
	var children:ViewListReconciler;

	public function new(parent, node, adaptor) {
		this.parent = parent;
		this.node = node;
		this.adaptor = adaptor;
		this.children = new ViewListReconciler(this, adaptor);
		this.attributes = new PrimitiveAttributes((name, oldValue, newValue, ?hydrate) -> {
			if (primitive == null) return;
			adaptor.updatePrimitiveAttribute(primitive, name, oldValue, newValue, hydrate);
		});
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
					primitive = adaptor.checkPrimitiveType(current, node.tag)
						.mapError(e -> ViewError.HydrationMismatch(this, node.tag, current))
						.orReturn();
					cursor.next();
				default:
					return Error(ViewError.NoNodeFoundDuringHydration(this, node.tag));
			}
		} else {
			primitive = adaptor.createPrimitive(node.tag);
			cursor.insert(primitive)
				.mapError(_ -> ViewError.InsertionFailed(this))
				.orReturn();
		}

		attributes.reconcile(node.attributes, hydrate);
		children
			.reconcile(node.children.or([]), adaptor.children(primitive), hydrate)
			.orReturn();

		return Ok(this);
	}

	public function update(parent:Maybe<View>, node:Node, cursor:Cursor):Result<View, ViewError> {
		this.parent = parent;
		this.node = this.node.replaceWith(node, this).orReturn();

		cursor.insert(primitive)
			.mapError(_ -> ViewError.InsertionFailed(this))
			.orReturn();

		attributes.reconcile(this.node.attributes);
		children
			.reconcile(this.node.children.or([]), adaptor.children(primitive))
			.orReturn();

		return Ok(this);
	}

	public function remove(cursor:Cursor):Result<View, ViewError> {
		disposables?.dispose();
		children.remove(adaptor.children(primitive)).orReturn();
		cursor.remove(primitive)
			.mapError(e -> ViewError.CausedException(this, e))
			.orReturn();
		attributes.dispose();

		return Ok(this);
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		children.each(visitor);
	}

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

class PrimitiveAttributes<Attrs:{}> implements Disposable {
	final attributes:Map<String, PrimitiveAttribute<Any>> = [];
	final setAttribute:(name:String, oldValue:Any, newValue:Any, ?hydrate:Bool) -> Void;

	public function new(setAttribute) {
		this.setAttribute = setAttribute;
	}

	public function reconcile(attrs:Attrs, ?hydrate:Bool) {
		var fields = Reflect.fields(attrs);

		for (name in attributes.keys()) {
			if (!fields.contains(name)) {
				attributes.get(name)?.dispose();
				attributes.remove(name);
			}
		}

		for (name in fields) {
			var signal:ReadOnlySignal<Any> = Reflect.field(attrs, name);
			var updater = attributes.get(name);

			if (signal == null) signal = new Signal(null);

			if (updater == null) {
				updater = new PrimitiveAttribute(name, signal, setAttribute);
				attributes.set(name, updater);
			} else {
				updater.update(signal);
			}
		}
	}

	public function dispose() {
		for (attribute in attributes) {
			attribute.dispose();
		}
		attributes.clear();
	}
}

class PrimitiveAttribute<T> implements Disposable {
	final name:String;
	final changeSignal:Signal<ReadOnlySignal<T>>;
	final owner:Owner = new Owner();
	final setAttribute:(name:String, oldValue:T, newValue:T, ?hydrate:Bool) -> Void;
	var oldValue:Null<T> = null;

	public function new(name:String, propSignal:ReadOnlySignal<T>, setAttribute) {
		this.name = name;
		this.setAttribute = setAttribute;
		this.changeSignal = new Signal(propSignal);
		Owner.capture(owner, {
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
		setAttribute(name, oldValue, null);
	}
}
