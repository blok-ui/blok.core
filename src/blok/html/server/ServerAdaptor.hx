package blok.html.server;

import blok.engine.*;
import blok.core.*;

using StringTools;

class ServerAdaptor implements Adaptor {
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
		if (tag.startsWith('svg:')) tag = tag.substr(4);
		return new ElementPrimitive(tag);
	}

	public function createTextPrimitive(text:String):Any {
		return new TextPrimitive(text);
	}

	public function createContainerPrimitive():Any {
		return new ElementPrimitive('div');
	}

	public function updateTextPrimitive(primitive:Any, value:String) {
		var text:TextPrimitive = primitive;
		text.updateContent(value);
	}

	public function updatePrimitiveAttribute(primitive:Any, name:String, oldValue:Null<Any>, value:Any, ?isHydrating:Bool) {
		var el:ElementPrimitive = primitive;
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

	public function checkPrimitiveType(primitive:Any, type:String):Result<Any, Error> {
		if (!(primitive is ElementPrimitive)) return Error(new Error(InternalError, 'Not an Element'));

		var node:ElementPrimitive = primitive;

		if (node.tag != type) return Error(new Error(InternalError, 'Not a ${type}'));

		return Ok(node);
	}

	public function checkText(primitive:Any):Result<Any, Error> {
		if (primitive is TextPrimitive) return Ok(primitive);
		return Error(new Error(InternalError, 'Not Text'));
	}

	public function children(primitive:Any):Cursor {
		var parent:NodePrimitive = primitive;
		var node = parent.children[0];

		return new ServerCursor(parent, node);
	}

	public function siblings(primitive:Any):Cursor {
		var node:NodePrimitive = primitive;
		var parent = node.parent;

		return new ServerCursor(parent, node);
	}

	public function removePrimitive(primitive:Any) {
		var node:NodePrimitive = primitive;
		node.remove();
	}
}

// @todo: Figure out how to use the @:html attributes for this instead.
function getHtmlName(name:String) {
	if (name.startsWith('aria')) {
		return 'aria-' + name.substr(4).toLowerCase();
	}
	return name;
}
