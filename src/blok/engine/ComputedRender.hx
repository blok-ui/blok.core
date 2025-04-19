package blok.engine;

import blok.debug.Debug;
import blok.signal.Computation;
import blok.engine.Differ;

using blok.BoundaryTools;

interface ComputedRenderHost {
	public var __computedRender:Null<ComputedRender>;
}

// @todo: This is not used yet, but might be a replacement for ProxyView?
class ComputedRender {
	final view:View;
	final setup:() -> Void;
	final render:Isolate<VNode>;
	final computedRender:Computation<VNode>;

	var child:Null<View> = null;

	public function new(view, render, setup) {
		this.view = view;
		this.render = render;
		this.setup = setup;
		Owner.capture(view, {
			computedRender = Computation.persist(() -> switch view.__status {
				case Disposing | Disposed:
					Placeholder.node();
				default:
					var node = try render() catch (e:Any) {
						render.cleanup();
						view.tryToHandleWithBoundary(e);
						null;
					}
					if (view.__status != Rendering) view.invalidate();
					node ?? Placeholder.node();
			});
		});
	}

	public function mount() {
		child = computedRender.peek().createView();
		child.mount(view.getAdaptor(), view, view.__slot);
		Owner.capture(view, {
			setup();
		});
	}

	public function hydrate(cursor:Cursor) {
		child = computedRender.peek().createView();
		child.hydrate(cursor, view.getAdaptor(), view, view.__slot);
		Owner.capture(view, {
			setup();
		});
	}

	public function update() {
		child = updateView(view, child, computedRender.peek(), view.__slot);
	}

	public function updateSlot(slot:Slot) {
		child?.updateSlot(slot);
	}

	public function replace(other:View):Bool {
		if (!(other is ComputedRenderHost)) {
			return false;
		}

		var host:ComputedRenderHost = cast other;

		if (host.__computedRender == null) return false;

		var otherChild = host.__computedRender.child;

		host.__computedRender.child = null;
		child = updateView(view, otherChild, computedRender.peek(), view.__slot);

		Owner.capture(view, {
			setup();
		});

		return true;
	}

	public function getPrimitive() {
		if (child == null) {
			error('View does not have a primitive');
		}
		return child.getPrimitive();
	}

	public function visit(visitor:(child:View) -> Bool) {
		if (child != null) visitor(child);
	}
}
