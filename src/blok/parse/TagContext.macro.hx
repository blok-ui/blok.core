package blok.parse;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using blok.parse.ParseTools;

enum TagContextKind {
	Root;
	Child(parent:TagContext);
}

class TagContext {
	final tags:Map<String, Tag> = [];
	final kind:TagContextKind;
	final builtins:Array<String>;

	public function new(kind, builtins) {
		this.kind = kind;
		this.builtins = builtins;
	}

	function getBuiltins() {
		return switch kind {
			case Root:
				builtins;
			case Child(parent):
				parent.getBuiltins().concat(builtins);
		}
	}

	public function resolve(name:Located<String>):Tag {
		return switch tags.get(name.value) {
			case null:
				switch Context.getLocalTVars().get(name.value) {
					case null if (name.value.isComponentName()):
						var type = Context.typeof(macro @:pos(name.pos) $p{name.value.toPath()});
						tags[name.value] = Tag.fromType(name, type);
					case null:
						for (source in getBuiltins()) {
							var type = Context.getType(source);
							switch type {
								default:
								case TInst(t, _):
									var statics = t.get().statics.get().filter(f -> !f.meta.has(':skip'));
									var field = statics.find(f -> f.name == name.value);
									if (field != null) {
										return tags[name.value] = Tag.fromType({
											value: source + '.' + name.value,
											pos: name.pos
										}, field.type, true);
									}
							}
						}
						Context.error('Unknown tag: <${name.value}>', name.pos);
					case type:
						tags[name.value] = Tag.fromType(name, type.t);
				}
			case tag:
				tag;
		}
	}
}
