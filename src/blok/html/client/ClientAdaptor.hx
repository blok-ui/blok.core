package blok.html.client;

import blok.adaptor.*;
import blok.core.Scheduler;
import blok.debug.Debug;
import blok.html.HtmlEvents;
import blok.ui.*;
import js.Browser;
import js.html.Element;

using StringTools;

inline extern final svgNamespace = 'http://www.w3.org/2000/svg';

class ClientAdaptor implements Adaptor {
	final scheduler:Scheduler;

	public function new() {
		// scheduler = getCurrentScheduler().orThrow('No scheduler available');
		scheduler = Scheduler.current();
	}

	public function createNode(name:String, initialAttrs:{}):Dynamic {
		return name.startsWith('svg:') ? Browser.document.createElementNS(svgNamespace, name.substr(4)) : Browser.document.createElement(name);
	}

	public function createTextNode(value:String):Dynamic {
		return Browser.document.createTextNode(value);
	}

	public function createContainerNode(props:{}):Dynamic {
		return createNode('div', props);
	}

	public function createPlaceholderNode():Dynamic {
		return createTextNode('');
	}

	public function createCursor(object:Dynamic):Cursor {
		return new ClientCursor(object);
	}

	public function updateTextNode(object:Dynamic, value:String) {
		(object : js.html.Text).textContent = value;
	}

	public function updateNodeAttribute(object:Dynamic, name:String, oldValue:Null<Dynamic>, value:Null<Dynamic>, ?isHydrating:Bool) {
		var el:Element = object;
		var isSvg = el.namespaceURI == svgNamespace;
		var namespace = isSvg ? svgNamespace : null;

		name = normalizeAttributeName(name);

		if (isHydrating) {
			if (name.startsWith('on')) {
				updateEventListener(el, name, value);
			}
			return;
		}

		switch name {
			case 'xmlns' if (isSvg): // skip
			case 'value' | 'selected' | 'checked' if (!isSvg):
				js.Syntax.code('{0}[{1}] = {2}', el, name, value);
			case _ if (name.startsWith('on')):
				updateEventListener(el, name, value);
			case _ if (!isSvg && value != null && js.Syntax.code('{0} in {1}', name, el)):
				// @todo: Not sure if this is the best idea for setting props.
				js.Syntax.code('{0}[{1}] = {2}', el, name, value);
			default:
				setAttribute(el, name, value, namespace);
		}
	}

	public function insertNode(object:Dynamic, slot:Null<Slot>, findParent:() -> Dynamic) {
		var el:js.html.Element = object;
		if (slot != null && slot.previous != null) {
			var relative:js.html.Element = slot.previous.getPrimitive();
			relative.after(el);
		} else {
			var parent:js.html.Element = findParent();
			assert(parent != null);
			parent.prepend(el);
		}
	}

	public function moveNode(object:Dynamic, from:Null<Slot>, to:Null<Slot>, findParent:() -> Dynamic) {
		var el:js.html.Element = object;

		if (to == null) {
			if (from != null) {
				removeNode(object, from);
			}
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
			var parent:js.html.Element = findParent();
			assert(parent != null);
			parent.prepend(el);
			return;
		}

		var relative:js.html.Element = to.previous.getPrimitive();
		assert(relative != null);
		relative.after(el);
	}

	public function removeNode(object:Dynamic, slot:Null<Slot>) {
		(object : Element).remove();
	}

	public function schedule(effect:() -> Void) {
		scheduler.schedule(effect);
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

	function updateEventListener(element:Element, name:String, ?handler:EventListener) {
		// @todo: Look into delegation?

		// @todo: We're not actually using `addEventListener` here as we
		// don't currently have things set up to remove old ones.
		// Instead, we're setting properties. This seems a bit questionable
		// as a concept, so it's just a short-term solution.
		var name = name.toLowerCase();
		if (handler == null) {
			Reflect.setField(element, name, cast null);
		} else {
			Reflect.setField(element, name, handler);
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
