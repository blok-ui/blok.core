package blok.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using Lambda;
using haxe.macro.Tools;
using blok.macro.Tools;
using kit.macro.Tools;

class UseFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':use')) {
			parseField(builder, field.getMetadata(':use'), field);
		}
	}

	function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
		var name = field.name;

		if (!field.access.contains(AFinal)) {
			field.pos.error(':use fields must be final');
		}

		switch field.kind {
			case FVar(null, _):
				field.pos.error('Expected a type');
			case FVar(_, null):
				field.pos.error('Expected an expression');
			case FVar(t, _) if (!Context.unify(t.toType(), 'blok.hook.Hook'.toComplex().toType())):
				field.pos.error(':use fields must be block.hook.Hooks');
			case FVar(t, e):
				field.kind = FVar(t, null);
				builder.hook(LateInit)
					.addExpr(macro this.$name = $e);
				builder.setupHook()
					.addExpr(macro {
						this.$name.setup(this);
						this.addDisposable(this.$name);
					});
			default:
				meta.pos.error(':use cannot be used here');
		}
	}
}
