package blok.parse;

import haxe.macro.Context;
import haxe.macro.Expr;

abstract class Generator {
  public function generate(nodes:Array<Node>):Expr {
    var exprs = [ for (node in nodes) generateNode(node) ];
    return switch exprs {
      case []: macro null;
      case [expr]: expr;
      case exprs: macro blok.ui.Fragment.node($a{exprs});
    }
  }
  
  function generateNode(node:Node):Expr {
    return switch node.node {
      case NFragment(children): 
        generateFragment(children, node.pos);
      case NNode(tag, attributes, children): switch tag {
        case TagBuiltin(name):
          generateBuiltinNode(name, attributes, children, node.pos);
        case TagComponent(path): 
          generateComponent(path, attributes, children, node.pos);
        case TagAttribute(name):
          Context.error('Unhandled attribute node $name. These should be children of a Component or Builtin node.', node.pos);
      }
      case NText(text):
        macro blok.ui.Text.node($v{text});
      case NExpr(expr):
        expr;
    }
  }

  abstract function generateBuiltinNode(
    name:String,
    attributes:Array<Attribute>,
    children:Array<Node>,
    pos:Position
  ):Expr;

  function generateFragment(children:Array<Node>, pos:Position):Expr {
    var components = children.map(generateNode);
    return macro blok.ui.Fragment.node($a{components});
  }

  function generateComponent(
    path:Array<String>,
    attributes:Array<Attribute>,
    children:Array<Node>,
    pos:Position
  ):Expr {
    attributes = attributes.concat(extractAttributes(children));

    if (children.length > 0) {
      Context.error('Only attribute children are allowed here', children[0].pos);
    }

    return macro $p{path}.node(${{
      expr: EObjectDecl(attributesToObjectFields(attributes)),
      pos: pos // ??
    }});
  }

  function extractAttributes(children:Array<Node>):Array<Attribute> {
    var extractedAttributes:Array<Attribute> = [];
    var ref = children.copy();
    for (child in ref) switch child.node {
      case NNode(TagAttribute(name), localAttributes, localChildren):
        children.remove(child);
        if (localAttributes.length > 0) Context.error('Attribute nodes cannot have attributes', localAttributes[0].name.pos);
        if (localChildren.length > 1) Context.error('Attribute notes may only have one child', localChildren[0].pos);
        extractedAttributes.push({
          name: { value: name, pos: child.pos },
          value: localChildren.length == 0 
            ? ANone
            : AExpr(generateNode(localChildren[0]))
        });
      default:
    }
    return extractedAttributes;
  }

  function attributesToObjectFields(attributes:Array<Attribute>):Array<ObjectField> {
    return [ for (attr in attributes) ({
      field: attr.name.value,
      expr: switch attr.value {
        case ANone: macro null;
        case AExpr(expr): expr;
      }
    }:ObjectField) ];
  }
}
