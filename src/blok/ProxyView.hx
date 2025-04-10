package blok;

import blok.Differ;
import blok.debug.Debug;
import blok.signal.Computation;

using blok.BoundaryTools;

/**
	Implements basic functionality for views that return other views.

	Note: This is intended for internal use! You should use 
	`blok.Component`s instead in almost all cases.
**/
abstract class ProxyView extends View {
	@:noCompletion var __child:Null<View> = null;
	@:noCompletion var __rendered:Null<Computation<Null<VNode>>> = null;

	abstract function setup():Void;

	abstract function render():Child;

	@:noCompletion abstract function __updateProps():Void;

	@:noCompletion function __createRendered() {
		return Owner.capture(this, {
			var isolate = new Isolate(render);
			Computation.untracked(() -> switch __status {
				case Disposing | Disposed:
					Placeholder.node();
				default:
					var node = try isolate() catch (e:Any) {
						isolate.cleanup();
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
		Owner.capture(this, {
			setup();
		});
	}

	@:noCompletion function __hydrate(cursor:Cursor):Void {
		assert(__rendered == null);
		__rendered = __createRendered();
		__child = __rendered.peek().createView();
		__child?.hydrate(cursor, getAdaptor(), this, __slot);
		Owner.capture(this, {
			setup();
		});
	}

	@:noCompletion override function __replace(other:View):Bool {
		if (!(other is ProxyView)) {
			return false;
		}

		var proxy:ProxyView = cast other;
		var otherChild = proxy.__child;

		assert(__rendered == null);
		__rendered = __createRendered();

		proxy.__child = null;
		__child = updateView(this, otherChild, __rendered.peek(), __slot);

		Owner.capture(this, {
			setup();
		});

		return true;
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
			assert(node == null, 'Component has more than one primitive');
			node = component.getPrimitive();
			true;
		});

		assert(node != null, 'Component does not have a primitive');

		return node;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (__child != null) visitor(__child);
	}

	@:noCompletion function __dispose():Void {
		__rendered = null;
	}
}
