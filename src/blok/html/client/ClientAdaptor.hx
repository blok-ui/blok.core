package blok.html.client;

import blok.Scheduler;
import blok.debug.Debug;
import blok.html.HtmlEvents;
import js.Browser;
import js.html.Element;

using StringTools;

inline extern final svgNamespace = 'http://www.w3.org/2000/svg';

class ClientAdaptor implements Adaptor {
	final scheduler:Scheduler;

	public function new(?scheduler) {
		this.scheduler = scheduler ?? Scheduler.current();
	}

	public function createPrimitive(name:String, initialAttrs:{}):Dynamic {
		return name.startsWith('svg:') ? Browser.document.createElementNS(svgNamespace, name.substr(4)) : Browser.document.createElement(name);
	}

	public function createTextPrimitive(value:String):Dynamic {
		return Browser.document.createTextNode(value);
	}

	public function createContainerPrimitive(props:{}):Dynamic {
		return createPrimitive('div', props);
	}

	public function createPlaceholderPrimitive():Dynamic {
		return createTextPrimitive('');
	}

	public function createCursor(object:Dynamic):Cursor {
		return new ClientCursor(object);
	}

	public function updateTextPrimitive(object:Dynamic, value:String) {
		var text:js.html.Text = object;
		if (text.textContent == value) return; // Note: not doing this can cause unneeded updates.
		text.textContent = value;
	}

	public function updatePrimitiveAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Null<Dynamic>, ?isHydrating:Bool) {
		var el:Element = object;
		var isSvg = el.namespaceURI == svgNamespace;
		var namespace = isSvg ? svgNamespace : null;

		name = normalizeAttributeName(name);

		if (isHydrating) {
			if (name.startsWith('on')) {
				updateEventListener(el, name, oldValue, value);
			}
			return;
		}

		switch name {
			case 'xmlns' if (isSvg): // skip
			case 'value' | 'selected' | 'checked' if (!isSvg):
				js.Syntax.code('{0}[{1}] = {2}', el, name, value);
			case _ if (name.startsWith('on')):
				updateEventListener(el, name, oldValue, value);
			case _ if (!isSvg && value != null && js.Syntax.code('{0} in {1}', name, el)):
				// @todo: Not sure if this is the best idea for setting props.
				js.Syntax.code('{0}[{1}] = {2}', el, name, value);
			default:
				setAttribute(el, name, value, namespace);
		}
	}

	public function insertPrimitive(object:Dynamic, slot:Slot) {
		assert(slot != null);

		var el:Element = object;

		if (slot.previous != null) {
			var relative:Element = slot.previous.getPrimitive();
			relative.after(el);
		} else {
			var parent:Element = slot.parent.getNearestPrimitive();
			assert(parent != null);
			parent.prepend(el);
		}
	}

	public function movePrimitive(object:Dynamic, from:Null<Slot>, to:Null<Slot>) {
		var el:Element = object;

		if (to == null) {
			removePrimitive(object, from);
			return;
		}

		// // @todo: I don't think we need this: it's checked anyway
		// // during diffing and we want to ignore it if we're manually changing
		// // slots.
		// if (from != null && !from.changed(to)) {
		//   return;
		// }

		if (to.previous == null) {
			assert(to.index == 0);
			var parent:Element = to.parent.getNearestPrimitive();
			assert(parent != null);
			parent.prepend(el);
			return;
		}

		var relative:Element = to.previous.getPrimitive();
		assert(relative != null);
		relative.after(el);
	}

	public function removePrimitive(object:Dynamic, slot:Null<Slot>) {
		(object : Element).remove();
	}

	public function schedule(effect:() -> Void) {
		scheduler.schedule(effect);
	}

	public function scheduleEffect(effect:() -> Void) {
		scheduler.scheduleEffect(effect);
	}

	function setAttribute(element:Element, name:String, ?value:Dynamic, ?namespace:String) {
		var shouldRemove = value == null || (value is Bool && value == false);

		// if (shouldRemove) return if (namespace != null) {
		//   element.removeAttributeNS(namespace, name);
		// } else {
		//   element.removeAttribute(name);
		// }

		if (shouldRemove) {
			element.removeAttribute(name);
			return;
		}

		if (value is Bool && value == true) value = name;

		switch name {
			case 'class':
				updateClassList(element, value);
			case 'dataset':
				updateDataset(element, value);
			default:
				element.setAttribute(name, value);
				// if (namespace != null) {
				//   element.setAttributeNS(namespace, name, value);
				// } else {
				//   element.setAttribute(name, value);
				// }
		}
	}

	function updateClassList(element:Element, value:String) {
		var oldValue = element.classList.value;
		var oldNames = Std.string(oldValue ?? '').split(' ').filter(n -> n != null && n != '');
		var newNames = Std.string(value ?? '').split(' ').filter(n -> n != null && n != '');

		for (name in oldNames) {
			if (!newNames.contains(name)) {
				element.classList.remove(name);
			} else {
				newNames.remove(name);
			}
		}

		if (newNames.length > 0) {
			element.classList.add(...newNames);
		}
	}

	function updateDataset(element:Element, map:Map<String, String>) {
		for (key => value in map) {
			if (value == null) {
				Reflect.deleteField(element.dataset, key);
			} else {
				Reflect.setField(element.dataset, key, value);
			}
		}
	}

	// @todo: Look into delegation?
	function updateEventListener(element:Element, name:String, oldHandler:Null<EventListener>, handler:Null<EventListener>) {
		var name = name.substr(2).toLowerCase();

		if (oldHandler != null) {
			element.removeEventListener(name, oldHandler);
		}

		if (handler != null) {
			element.addEventListener(name, handler);
		}
	}

	function normalizeAttributeName(name:String) {
		name = name.trim();

		if (name.startsWith('aria')) {
			name = 'aria-' + name.substr(4).toLowerCase();
		}
		if (name == 'className') {
			name = 'class';
		}
		if (name == 'htmlFor') {
			name = 'for';
		}

		return name;
	}
}
