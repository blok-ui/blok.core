package blok;

import js.html.Node;
import blok.core.Context;
import blok.core.Differ;

class NodeType<Props:{}> {
  static var types:Map<String, NodeType<Dynamic>> = [];

  public static function get<Props:{}>(tag:String):NodeType<Props> {
    if (!types.exists(tag)) { 
      types.set(tag, new NodeType(tag));
    }
    return cast types.get(tag);
  }

  public static function updateNodeAttribute(node:Node, name:String, oldValue:Dynamic, newValue:Dynamic):Void {
    var el:js.html.Element = cast node;
    switch name {
      case 'className':
        updateNodeAttribute(node, 'class', oldValue, newValue);
      case 'value' | 'selected' | 'checked':
        js.Syntax.code('{0}[{1}] = {2}', el, name, newValue);
      case _ if (js.Syntax.code('{0} in {1}', name, el)):
        js.Syntax.code('{0}[{1}] = {2}', el, name, newValue);
      default:
        if (name.charAt(0) == 'o' && name.charAt(1) == 'n') {
          var name = name.toLowerCase();
          if (newValue == null) {
            Reflect.setField(el, name, null);
          } else {
            Reflect.setField(el, name, newValue);
          }
        } else if (newValue == null || (Std.is(newValue, Bool) && newValue == false)) {
          el.removeAttribute(name);
        } else if (Std.is(newValue, Bool) && newValue == true) {
          el.setAttribute(name, name);
        } else {
          el.setAttribute(name, newValue);
        }
    }
  }

  final tag:String;

  public function new(tag, isSvg = false) {
    this.tag = tag;
  }

  public function create(props:Props, context:Context<js.html.Node>):js.html.Node {
    var node = js.Browser.document.createElement(tag);
    Differ.diffObject(
      {}, 
      props, 
      updateNodeAttribute.bind(node)
    );
    return node;
  }

  public function update(
    node:js.html.Node, 
    previousProps:Props,
    props:Props,
    context:Context<js.html.Node>
  ):js.html.Node {
    Differ.diffObject(
      previousProps, 
      props, 
      updateNodeAttribute.bind(node)
    );
    return node;
  }
}