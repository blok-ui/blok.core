package blok.html.server;

import blok.Scheduler;
import blok.debug.Debug;
import blok.engine.*;

using StringTools;

class ServerAdaptor implements Adaptor {
	final scheduler:Scheduler;

	public function new(?scheduler) {
		this.scheduler = scheduler ?? Scheduler.current();
	}

	public function createPrimitive(name:String, attrs:{}):Dynamic {
		if (name.startsWith('svg:')) name = name.substr(4);
		return new ElementPrimitive(name, attrs);
	}

	public function createTextPrimitive(value:String):Dynamic {
		return new TextPrimitive(value);
	}

	public function createContainerPrimitive(props:{}):Dynamic {
		return createPrimitive('div', props);
	}

	public function createPlaceholderPrimitive():Dynamic {
		return new TextPrimitive('');
	}

	public function createCursor(object:Dynamic):Cursor {
		return new NodePrimitiveCursor(object);
	}

	public function updateTextPrimitive(object:Dynamic, value:String) {
		(object : TextPrimitive).updateContent(value);
	}

	public function updatePrimitiveAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Dynamic, ?isHydrating:Bool) {
		var el:ElementPrimitive = object;
		switch name {
			case 'className' | 'class':
				var oldNames = Std.string(oldValue ?? '').split(' ').filter(n -> n != null && n != '');
				var newNames = Std.string(value ?? '').split(' ').filter(n -> n != null && n != '');

				for (name in oldNames) {
					if (!newNames.contains(name)) {
						el.classList.remove(name);
					} else {
						newNames.remove(name);
					}
				}

				if (newNames.length > 0) {
					for (name in newNames) el.classList.add(name);
				}
			default:
				el.setAttribute(getHtmlName(name), value);
		}
	}

	public function insertPrimitive(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic) {
		var node:NodePrimitive = object;
		if (slot != null && slot.previous != null) {
			var relative:NodePrimitive = slot.previous.getPrimitive();
			var parent = relative.parent;
			if (parent != null) {
				var index = parent.children.indexOf(relative);
				parent.insert(index + 1, node);
			} else {
				var parent:NodePrimitive = findParent();
				assert(parent != null);
				parent.prepend(node);
			}
		} else {
			var parent:NodePrimitive = findParent();
			assert(parent != null);
			parent.prepend(node);
		}
	}

	public function movePrimitive(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic) {
		var node:NodePrimitive = object;

		if (to == null) {
			removePrimitive(object, from);
			return;
		}

		if (from != null && !from.changed(to)) {
			return;
		}

		if (to.previous == null) {
			var parent:NodePrimitive = findParent();
			assert(parent != null);
			parent.prepend(node);
			return;
		}

		var relative:NodePrimitive = to.previous.getPrimitive();
		var parent = relative.parent;

		assert(parent != null);

		var index = parent.children.indexOf(relative);

		parent.insert(index + 1, node);
	}

	public function removePrimitive(object:Dynamic, slot:Null<Slot>) {
		var node:NodePrimitive = object;
		node.remove();
	}

	public function schedule(effect:() -> Void) {
		scheduler.schedule(effect);
	}

	public function scheduleEffect(effect:() -> Void) {
		scheduler.scheduleEffect(effect);
	}
}

// @todo: Figure out how to use the @:html attributes for this instead.
function getHtmlName(name:String) {
	if (name.startsWith('aria')) {
		return 'aria-' + name.substr(4).toLowerCase();
	}
	return name;
}
