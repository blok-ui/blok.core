package blok.core;

import haxe.Exception;
import blok.ui.Component;

using Type;

class BlokException extends Exception {}

class BlokComponentException extends BlokException {
  public function new(message, component:Component) {
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
function getComponentDebugName(component:Component) {
  return component.getClass().getClassName();
}

function getComponentDescription(component:Component):String {
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