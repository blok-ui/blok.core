package blok.parse;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using kit.macro.Tools;
using haxe.macro.Tools;
using blok.macro.Tools;
using blok.parse.ParseTools;

// @todo: Figure out how to get this thing to enable completion.
// Starting to figure it out, but I think I'm still doing positions
// wrong. Completion is broken. Need to figure out how to map
// XML positions to Haxe positions correctly.
class Generator {
	var context:TagContext;

	public function new(context) {
		this.context = context;
	}

	public function generate(nodes:Array<Node>) {
		var exprs = [for (node in nodes) generateNode(node)];
		return switch exprs {
			case []: macro null;
			case [expr]: expr;
			case exprs: macro [$a{exprs}];
		}
	}

	public function generateNode(node:Node):Expr {
		return switch node.value {
			case NFragment(children):
				var children = children.map(generateNode);
				macro blok.Fragment.of([$a{children}]);
			case NNode(name, attributes, children):
				var prevContext = context;
				var tag = context.resolve(name);
				var props:Array<ObjectField> = [];

				function addProp(attr:Attribute) {
					if (props.exists(p -> p.field == attr.name.value)) {
						attr.name.pos.error('Attribute already exists');
					}

					props.push({
						field: attr.name.value,
						// @todo: Should be a way to do this where we don't
						// need to `prepareForDisplay` here.
						expr: attr.value.prepareForDisplay()
					});
				}

				context = new TagContext(Child(prevContext), [tag.fullName]);

				for (attr in attributes) {
					var attrType = tag.attributes.getAttribute(attr.name);
					if (attrType == null) {
						Context.error('Invalid attribute: ${attr.name.value}', attr.name.pos);
					}
					addProp(attr);
				}

				// @todo: This only sorta works -- it does NOT give us any completion but
				// it does highlight things sorta correctly.
				var attrPos = if (attributes.length > 0) Context.makePosition({
					min: attributes[0].name.pos.getInfos().min,
					max: attributes[attributes.length - 1].value.pos.getInfos().max,
					file: attributes[0].name.pos.getInfos().file
				}) else name.pos;

				function isAttributeChild(child:Node) return switch child.value {
					case NNode(name, attributes, children) if (tag.attributes.hasAttribute(name)):
						true;
					default:
						false;
				};

				var attrChildren = children.filter(isAttributeChild);
				var nodeChildren = children.filter(child -> !isAttributeChild(child));

				for (child in attrChildren) switch child.value {
					case NNode(name, attributes, children):
						if (attributes.length > 0) {
							// @todo: This error message is confusing.
							attributes[0].name.pos.error('Cannot use attributes on attribute nodes');
						}
						addProp({
							name: name,
							value: generate(children)
						});
					default:
				}

				var restArgs:Array<Expr> = [];

				switch tag.attributes.childrenAttribute {
					case None if (nodeChildren.length > 0):
						nodeChildren[0].pos.error('The tag ${tag.name} does not allow children');
					case Rest:
						restArgs = [for (child in children) generateNode(child)];
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
							value: generate(nodeChildren)
						});
					default:
				}

				context = prevContext;

				var args:Array<Expr> = [({
					expr: EObjectDecl(props),
					pos: attrPos
				}).prepareForDisplay()];
				var path:Array<String> = tag.isBuiltin ? tag.name.toPath() : name.value.toPath();

				var e = switch tag.kind {
					case FunctionCall:
						macro @:pos(name.pos) $p{path};
					case FromMarkupMethod(name) | FromMarkupMethodMacro(name):
						path = path.concat([name]);
						macro @:pos(name.pos) $p{path};
				}

				// @todo: If we were doing things right, this is the only place
				// we'd need to wrap the code in EDisplay.
				if (Context.containsDisplayPosition(name.pos)) {
					e = {expr: EDisplay(e, DKMarked), pos: e.pos};
				}

				args = args.concat(restArgs);
				return macro $e($a{args});
			case NText(text):
				macro blok.Text.node($v{text});
			case NExpr(expr):
				expr.prepareForDisplay();
		}
	}
}
