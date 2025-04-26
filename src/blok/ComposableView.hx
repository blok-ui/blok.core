package blok;

import blok.debug.Debug;
import blok.signal.Computation;

abstract class ComposableView extends View {
	@:noCompletion var __child:Null<View> = null;
	@:noCompletion var __computedChild:Null<Computation<Null<VNode>>> = null;

	abstract function setup():Void;

	abstract function render():Child;

	@:noCompletion abstract function __updateProps():Void;

	@:noCompletion function __createComputedChild() {
		assert(__computedChild == null);
		__computedChild = Owner.capture(this, {
			var isolate = new Isolate(render);
			Computation.persist(() -> switch __status {
				case Disposing | Disposed:
					Placeholder.node();
				default:
					var node = try isolate() catch (e:Any) {
						isolate.cleanup();
						__handleThrownObject(this, e);
						null;
					}
					if (__status != Rendering) invalidate();
					node ?? Placeholder.node();
			});
		});
	}

	@:noCompletion function __initialize():Void {
		__createComputedChild();
		__child = __computedChild.peek().createView();
		__child?.mount(getAdaptor(), this, __slot);
		Owner.capture(this, {
			setup();
		});
	}

	@:noCompletion function __hydrate(cursor:Cursor):Void {
		__createComputedChild();
		__child = __computedChild.peek().createView();
		__child?.hydrate(cursor, getAdaptor(), this, __slot);
		Owner.capture(this, {
			setup();
		});
	}

	@:noCompletion override function __replace(other:View):Bool {
		if (!(other is ComposableView)) {
			return false;
		}

		var proxy:ComposableView = cast other;
		var otherChild = proxy.__child;

		__createComputedChild();

		proxy.__child = null;
		__child = Differ.updateView(getAdaptor(), this, otherChild, __computedChild.peek(), __slot);

		Owner.capture(this, {
			setup();
		});

		return true;
	}

	@:noCompletion function __update():Void {
		assert(__computedChild != null);
		__updateProps();
		__child = Differ.updateView(getAdaptor(), this, __child, __computedChild.peek(), __slot);
	}

	@:noCompletion function __validate():Void {
		assert(__computedChild != null);
		__child = Differ.updateView(getAdaptor(), this, __child, __computedChild.peek(), __slot);
	}

	@:noCompletion function __updateSlot(oldSlot, newSlot:Null<Slot>) {
		__child?.updateSlot(newSlot);
	}

	public function getPrimitive():Dynamic {
		var primitive = __child.getPrimitive();
		assert(primitive != null, 'Component does not have a primitive');
		return primitive;
	}

	public function visitChildren(visitor:(child:View) -> Bool) {
		if (__child != null) visitor(__child);
	}

	@:noCompletion function __dispose():Void {
		__computedChild = null;
	}
}
