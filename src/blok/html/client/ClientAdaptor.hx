package blok.html.client;

import js.html.DocumentFragment;
import js.html.DOMElement;
import js.html.Node;
import blok.core.*;
import blok.engine.Adaptor;
import blok.engine.Cursor;
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

	public function schedule(effect:() -> Void) {
		scheduler.schedule(effect);
	}

	public function scheduleEffect(effect:() -> Void) {
		scheduler.scheduleEffect(effect);
	}

	public function createPrimitive(tag:String):Any {
		if (tag.startsWith('svg:')) {
			return Browser.document.createElementNS(svgNamespace, tag.substr(4));
		}

		return Browser.document.createElement(tag);
	}

	public function createTextPrimitive(text:String):Any {
		return Browser.document.createTextNode(text);
	}

	public function createContainerPrimitive():Any {
		return createPrimitive('div');
	}

	public function updateTextPrimitive(primitive:Any, value:String) {
		var text:js.html.Text = primitive;
		if (text.textContent == value) return; // Note: not doing this can cause unneeded updates.
		text.textContent = value;
	}

	public function updatePrimitiveAttribute(primitive:Any, name:String, oldValue:Null<Any>, value:Any, ?isHydrating:Bool) {
		var el:Element = primitive;
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

	public function checkPrimitiveType(primitive:Any, type:String):Result<Any, Error> {
		var node:Node = primitive;
		if (node.nodeName != type) {
			return Error(new Error(InternalError, 'Not a ${type}'));
		}
		return Ok(node);
	}

	public function checkText(primitive:Any):Result<Any, Error> {
		var node:Node = primitive;
		if (node.nodeType != Node.TEXT_NODE) {
			return Error(new Error(InternalError, 'Not Text'));
		}
		return Ok(node);
	}

	public function children(primitive:Any):Cursor {
		var parent:DOMElement = primitive;
		var node = parent.children.item(0);
		return new ClientCursor(parent, node);
	}

	public function siblings(primitive:Any):Cursor {
		var node:Node = primitive;
		var parent:DOMElement = node.parentElement;
		if (parent == null) parent = cast new DocumentFragment(); // Hm
		return new ClientCursor(parent, node);
	}
}
