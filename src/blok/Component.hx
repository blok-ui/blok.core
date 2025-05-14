package blok;

import blok.core.*;
import blok.engine.*;

// @todo: This is probably going to work best by just extending ComposedView.

@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements ViewHost implements DisposableHost implements Disposable {
	@:noCompletion
	final __disposables:DisposableCollection = new DisposableCollection();

	abstract public function render():Child;

	abstract public function setup():Void;

	public function findChildComponent<T:Component>(kind:Class<T>, ?recursive:Bool):Maybe<T> {
		return getView()
			.findChild(child -> switch Std.downcast(child, ComposedView) {
				case null: false;
				case view: Std.isOfType(view.state, kind);
			}, recursive)
			.map(view -> (cast view : {state: T}).state);
	}

	public function findAncestorComponent<T:Component>(kind:Class<T>) {
		return getView()
			.findAncestor(ancestor -> switch Std.downcast(ancestor, ComposedView) {
				case null: false;
				case view: Std.isOfType(view.state, kind);
			})
			.map(view -> (cast view : {state: T}).state);
	}

	public function addDisposable(disposable:DisposableItem) {
		__disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		__disposables.removeDisposable(disposable);
	}

	public function dispose() {
		__disposables.dispose();
	}
}

class ComponentNode<Props:{}> implements Node {
	public final key:Null<Key>;
	public final type:UniqueId;
	public final props:Props;
	public final factory:(node:ComponentNode<Props>, parent:Maybe<View>, adaptor:Adaptor) -> Component;

	public function new(type, props, factory, ?key) {
		this.type = type;
		this.props = props;
		this.factory = factory;
		this.key = key;
	}

	public function matches(other:Node):Bool {
		if (!(other is ComponentNode)) return false;

		var otherComponent:ComponentNode<Props> = cast other;

		return type == otherComponent.type && key == otherComponent.key;
	}

	public function createView(parent:Maybe<View>, adaptor:Adaptor):View {
		return factory(this, parent, adaptor).getView();
	}
}
