package blok.parse;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;

class Generator {
  var context:TagContext;

  public function new(context) {
    this.context = context;
  }

  public function generate(nodes:Array<Node>) {
    var exprs = [ for (node in nodes) generateNode(node) ];
    return switch exprs {
      case []: macro null;
      case [expr]: expr;
      case exprs: macro blok.ui.Fragment.node($a{exprs});
    }
  }

  public function generateNode(node:Node):Expr {
    return switch node.node {
      case NFragment(children):
        var components = children.map(generateNode);
        macro blok.ui.Fragment.node($a{components});
      case NNode(name, attributes, children):
        var prevContext = context;
        var tag = context.resolve(name);
        var props:Array<ObjectField> = [];

        function addProp(attr:Attribute) {
          if (props.exists(p -> p.field == attr.name.value)) {
            Context.error('Attribute already exists', attr.name.pos);
          }
          props.push({
            field: attr.name.value,
            expr: switch attr.value {
              case ANone: macro null;
              case AExpr(expr): expr;
            } 
          });
        }

        context = new TagContext(Child(prevContext), [tag.fullName]);
        
        for (attr in attributes) {
          var attrType = tag.attributes.getAttribute(attr.name);
          if (attrType == null) {
            Context.error('Invalid attribute: ${attr.name.value}', attr.name.pos);
          }
          // @todo: We can do type checking here too
          addProp(attr);
        }
        
        function isAttributeChild(child:Node) return switch child.node {
          case NNode(name, attributes, children) if (tag.attributes.hasAttribute(name)):
            true;
          default:
            false;
        };

        var attrChildren = children.filter(isAttributeChild);
        var nodeChildren = children.filter(child -> !isAttributeChild(child));

        for (child in attrChildren) switch child.node {
          case NNode(name, attributes, children):
            if (attributes.length > 0) {
              // @todo: This error message is confusing.
              Context.error('Cannot use attributes on attribute nodes', attributes[0].name.pos);
            }
            addProp({
              name: name,
              value: AExpr(generate(children))
            });
          default:
        }

        var restArgs:Array<Expr> = [];

        switch tag.attributes.childrenAttribute {
          case None if (nodeChildren.length > 0):
            Context.error('The tag ${tag.name} does not allow children', nodeChildren[0].pos);
          case Rest:
            restArgs = [ for (child in children) generateNode(child) ];
          case Field(name, field) if (nodeChildren.length > 0):
            addProp({
              name: {
                value: name,
                pos: Context.makePosition({
                  min: nodeChildren[0].pos.getInfos().min,
                  max: nodeChildren[nodeChildren.length - 1].pos.getInfos().max,
                  file: nodeChildren[0].pos.getInfos().file,
                })
              },
              value: AExpr(generate(nodeChildren))
            });
          default:
        }

        context = prevContext;

        var args:Array<Expr> = [{
          expr: EObjectDecl(props),
          pos: name.pos
        }];
        var path:Array<String> = tag.isBuiltin 
          ? tag.name.split('.')
          : name.value.split('.');

        trace(path);
        
        var e = switch tag.kind {
          case FunctionCall:
            macro @:pos(name.pos) $p{path};
          case FromMarkupMethod:
            path = path.concat([Tag.fromMarkup]);
            macro @:pos(name.pos) $p{path};
        }

        #if (haxe_ver >= 4.1)
        if (Context.containsDisplayPosition(e.pos)) {
          e = {expr: EDisplay(e, DKMarked), pos: e.pos};
        }
        #end

        args = args.concat(restArgs);
        return macro @:pos(name.pos) $e($a{args});
      case NText(text):
        macro blok.ui.Text.node($v{text});
      case NExpr(expr):
        expr;
    }
  }
}