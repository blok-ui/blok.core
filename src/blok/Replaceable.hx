package blok;

import blok.debug.Debug;

enum ReplaceableStatus {
	Pending;
	Disposed;
	Visible(view:View);
	Hidden(placeholder:View, view:View);
}

class Replaceable implements Disposable {
	final parent:View;

	var hiddenRoot:Null<View> = null;
	var hiddenSlot:Null<Slot> = null;
	var status:ReplaceableStatus = Pending;

	public function new(parent) {
		this.parent = parent;
	}

	public function setup(view) {
		assert(status == Pending);

		status = Visible(view);

		var adaptor = parent.getAdaptor();

		hiddenRoot = Root.node({
			target: adaptor.createContainerPrimitive({}),
			child: Placeholder.node()
		}).createView();

		hiddenRoot.mount(adaptor, null, null);
		hiddenSlot = hiddenRoot.createSlot(1, hiddenRoot.findChildOfType(Placeholder).unwrap());
	}

	public function current() {
		return switch status {
			case Pending | Disposed: null;
			case Visible(view): view;
			case Hidden(placeholder, _): placeholder;
		};
	}

	public function real() {
		return switch status {
			case Pending | Disposed: null;
			case Visible(view): view;
			case Hidden(_, view): view;
		};
	}

	public function hide(placeholder:() -> Child) {
		if (!parent.viewIsMounted()) return;

		switch status {
			case Pending | Disposed:
				error('Attempted to hide an unmounted ReplaceableViewController');
			case Visible(view):
				view.updateSlot(hiddenSlot);
				var current = placeholder().createView();
				current.mount(parent.getAdaptor(), parent, parent.__slot);
				status = Hidden(current, view);
			case Hidden(_, _):
		}
	}

	public function show() {
		if (!parent.viewIsMounted()) return;

		switch status {
			case Pending | Disposed:
				error('Attempted to hide an unmounted ReplaceableViewController');
			case Visible(view):
				view.updateSlot(parent.__slot);
			case Hidden(placeholder, view):
				placeholder.dispose();
				view.updateSlot(parent.__slot);
				status = Visible(view);
		}
	}

	public function dispose() {
		hiddenRoot.dispose();

		switch status {
			case Pending | Disposed:
			case Visible(view):
				view.dispose();
			case Hidden(placeholder, view):
				placeholder.dispose();
				view.dispose();
		}

		status = Disposed;
	}
}
