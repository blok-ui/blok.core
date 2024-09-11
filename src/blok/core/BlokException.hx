package blok.core;

import blok.ui.View;
import haxe.Exception;

using Type;

class BlokException extends Exception {}

class BlokComponentException extends BlokException {
	public function new(message, component:View) {
		super([
			message,
			'',
			'Component tree:',
			'',
			getComponentDescription(component)
		].join('\n'));
	}
}

@:nullSafety(Off)
function getComponentDebugName(component:View) {
	return component.getClass().getClassName();
}

function getComponentDescription(component:View):String {
	var name = getComponentDebugName(component);
	var ancestor = try component.getParent().unwrap() catch (e) null;
	var stack = [while (ancestor != null) {
		var name = getComponentDebugName(ancestor);
		ancestor = try ancestor.getParent().unwrap() catch (e) null;
		name;
	}];
	stack.reverse();
	stack.push(name);
	return [for (index => name in stack) {
		var padding = [for (_ in 0...index) '  '].join('');
		if (index == stack.length - 1) '$padding-> $name' else '$padding$name';
	}].join('\n');
}
