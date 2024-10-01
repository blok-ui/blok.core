package blok.ui;

import blok.adaptor.Cursor;
import blok.core.Owner;
import blok.debug.Debug;
import blok.diffing.Differ;
import blok.signal.Computation;
import blok.signal.Isolate;

using blok.boundary.BoundaryTools;

/**
	Implements basic functionality for views that return other views.

	Note: This is intended for internal use! You should use 
	`blok.ui.Component`s instead in almost all cases.
**/
abstract class ProxyView extends View {
	@:noCompletion var __isolatedRender:Null<Isolate<VNode>> = null;
	@:noCompletion var __child:Null<View> = null;
	@:noCompletion var __rendered:Null<Computation<Null<VNode>>> = null;

	abstract function setup():Void;

	abstract function render():Child;

	@:noCompletion abstract function __updateProps():Void;

	@:noCompletion function __createRendered() {
		return Owner.with(this, () -> {
			__isolatedRender = new Isolate(render);
			return Computation.untracked(() -> switch __status {
				case Disposing | Disposed:
					Placeholder.node();
				default:
					var node = try __isolatedRender() catch (e:Any) {
						__isolatedRender.cleanup();
						this.tryToHandleWithBoundary(e);
						null;
					}
					if (__status != Rendering) invalidate();
					node ?? Placeholder.node();
			});
		});
	}

	@:noCompletion function __initialize():Void {
		assert(__rendered == null);
		__rendered = __createRendered();
		__child = __rendered.peek().createView();
		__child?.mount(getAdaptor(), this, __slot);
		Owner.with(this, setup);
	}

	@:noCompletion function __hydrate(cursor:Cursor):Void {
		assert(__rendered == null);
		__rendered = __createRendered();
		__child = __rendered.peek().createView();
		__child?.hydrate(cursor, getAdaptor(), this, __slot);
		Owner.with(this, setup);
	}

	@:noCompletion function __update():Void {
		assert(__rendered != null);
		__updateProps();
		__child = updateView(this, __child, __rendered.peek(), __slot);
	}

	@:noCompletion function __validate():Void {
		assert(__rendered != null);
		__child = updateView(this, __child, __rendered.peek(), __slot);
	}

	@:noCompletion function __updateSlot(oldSlot, newSlot:Null<Slot>) {
		__child?.updateSlot(newSlot);
	}

	public function getPrimitive() {
		var node:Null<Dynamic> = null;

		visitChildren(component -> {
			assert(node == null, 'Component has more than one real nodes');
			node = component.getPrimitive();
			true;
		});

		assert(node != null, 'Component does not have a real node');

		return node;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (__child != null) visitor(__child);
	}

	@:noCompletion function __dispose():Void {
		__isolatedRender = null;
		__rendered = null;
	}
}
