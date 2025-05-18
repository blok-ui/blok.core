package blok;

import blok.core.*;
import blok.engine.*;

@:autoBuild(blok.ComponentBuilder.build())
abstract class Component implements ComponentLike implements DisposableHost {
	@:noCompletion
	final __disposables:DisposableCollection = new DisposableCollection();

	public function investigate() {
		return new ComponentInvestigator(cast getView());
	}

	abstract public function render():Child;

	abstract public function setup():Void;

	public function addDisposable(disposable:DisposableItem) {
		__disposables.addDisposable(disposable);
	}

	public function removeDisposable(disposable:DisposableItem) {
		__disposables.removeDisposable(disposable);
	}
}

class ComponentNode<Props:{}> implements Node {
	public final key:Null<Key>;
	public final type:UniqueId;
	public final props:Props;
	public final factory:(node:ComponentNode<Props>, parent:Maybe<View>, adaptor:Adaptor) -> IntoView;

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
		return factory(this, parent, adaptor);
	}
}

interface ComponentLike extends ViewHost {
	public function investigate():ComponentInvestigator;
}

abstract ComponentInvestigator(ComposableView<Dynamic, Dynamic>) {
	public inline function new(view) {
		this = view;
	}

	public inline function getPrimitive() {
		return this.firstPrimitive();
	}

	public inline function getStatus():ViewStatus {
		return this.status;
	}

	public inline function isMounted() {
		return switch getStatus() {
			case Disposing | Disposed: false;
			default: true;
		}
	}

	public inline function isHydrating() {
		return switch getStatus() {
			case Rendering(Hydrating): true;
			default: false;
		}
	}

	public inline function isRendering() {
		return switch getStatus() {
			case Rendering(_): true;
			default: false;
		}
	}

	public inline function filterComponents<T:ComponentLike>(kind:Class<T>, ?recursive:Bool):Array<T> {
		return this
			.filterChildren(child -> switch Std.downcast(child, ComposableView) {
				case null: false;
				case view: Std.isOfType(view.state, kind);
			}, recursive)
			.map(view -> (cast view : {state: T}).state);
	}

	public inline function findComponent<T:ComponentLike>(kind:Class<T>, ?recursive:Bool):Maybe<T> {
		return this
			.findChild(child -> switch Std.downcast(child, ComposableView) {
				case null: false;
				case view: Std.isOfType(view.state, kind);
			}, recursive)
			.map(view -> (cast view : {state: T}).state);
	}

	public inline function findAncestorComponent<T:ComponentLike>(kind:Class<T>) {
		return this
			.findAncestor(ancestor -> switch Std.downcast(ancestor, ComposableView) {
				case null: false;
				case view: Std.isOfType(view.state, kind);
			})
			.map(view -> (cast view : {state: T}).state);
	}

	public inline function getParent():Maybe<View> {
		return this.currentParent();
	}

	public inline function findAncestor(match:(ancestor:View) -> Bool):Maybe<View> {
		return this.findAncestor(match);
	}

	public inline function findAncestorOfType<T:View>(kind:Class<T>):Maybe<T> {
		return this.findAncestorOfType(kind);
	}

	public inline function filterChildren(match, ?recursive) {
		return this.filterChildren(match, recursive);
	}

	public inline function findChild(match, ?recursive) {
		return this.findChild(match, recursive);
	}

	public inline function filterChildrenOfType<T:View>(kind:Class<T>, ?recursive) {
		return this.filterChildrenOfType(kind, recursive);
	}

	public inline function findChildOfType<T:View>(kind:Class<T>, ?recursive) {
		return this.findChildOfType(kind, recursive);
	}
}
