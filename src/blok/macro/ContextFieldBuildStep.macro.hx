package blok.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using haxe.macro.Tools;
using kit.macro.Tools;

class ContextFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':context')) {
			parseField(builder, field);
		}
	}

	function parseField(builder:ClassBuilder, field:Field) {
		switch field.kind {
			case FVar(t, e):
				if (!field.access.contains(AFinal)) {
					field.pos.error(':context fields must be final');
				}
				if (t == null) {
					field.pos.error(':context fields require a type');
				}
				if (e != null) {
					e.pos.error(':context fields cannot have an expression');
				}
				if (!Context.unify(t.toType(), 'blok.Context'.toComplex().toType())) {
					field.pos.error(':context fields need to be a blok.Context');
				}

				var name = field.name;
				var backingName = '__context_$name';
				var getterName = 'get_$name';
				var path = switch t {
					case TPath(p): p.pack.concat([p.name, p.sub]).filter(n -> n != null);
					default: throw 'assert';
				}

				field.kind = FProp('get', 'never', t);

				builder.add(macro class {
					var $backingName:Null<$t> = null;

					function $getterName():$t {
						if (this.$backingName == null) {
							this.$backingName = $p{path}.from(this);
						}
						return this.$backingName;
					}
				});
			default:
				field.pos.error(':context fields must be variables.');
		}
	}
}
