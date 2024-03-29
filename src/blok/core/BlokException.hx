package blok.core;

import blok.ui.ComponentBase;
import haxe.Exception;

using Type;

class BlokException extends Exception {}

class BlokComponentException extends BlokException {
  public function new(message, component:ComponentBase) {
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
function getComponentDebugName(component:ComponentBase) {
  return component.getClass().getClassName();
}

function getComponentDescription(component:ComponentBase):String {
  var name = getComponentDebugName(component);
  var ancestor = component.__parent;
  var stack = [ while (ancestor != null) {
    var name = getComponentDebugName(ancestor);
    ancestor = ancestor.__parent;
    name;
  } ];
  stack.reverse();
  stack.push(name);
  return [ for (index => name in stack) {
    var padding = [ for (_ in 0...index) '  ' ].join('');
    if (index == stack.length - 1) '$padding-> $name' else '$padding$name';
  } ].join('\n');
}