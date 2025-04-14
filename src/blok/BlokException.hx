package blok;

import blok.View;
import haxe.Exception;

using Type;

class BlokException extends Exception {}

class BlokViewException extends BlokException {
	public function new(message, view:View) {
		super([
			message,
			'',
			'Component tree:',
			'',
			getComponentDescription(view)
		].join('\n'));
	}
}

@:nullSafety(Off)
function getComponentDebugName(view:View) {
	return view.getClass().getClassName();
}

function getComponentDescription(view:View):String {
	var name = getComponentDebugName(view);
	var ancestor = try view.getParent().unwrap() catch (e) null;
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
