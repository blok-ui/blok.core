package blok.exception;

import haxe.Exception;
import blok.ui.Widget;

using Type;

// Todo: this needs to actually print a useful tree.
function getWidgetInheritance(component:Widget) {
  var tree:Array<String> = [];
  var current = component;
  while (current != null) {
    var comp = current;
    if (comp != null) {
      tree.unshift(comp.getClass().getClassName());
    }
    current = comp.__parent;
  }
  return tree;
}

class BlokException extends Exception {
  public function new(message, component:Widget, ?previous) {
    var tree = getWidgetInheritance(component);
    message = message + ' : ' + tree.join(' -> ');
    super(message, previous);
  }
}
