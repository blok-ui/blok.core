package blok.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import kit.macro.*;

class ConstantFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':constant')) {
			parseField(builder, field);
		}
	}

	function parseField(builder:ClassBuilder, field:Field) {
		switch field.kind {
			case FVar(t, e):
				if (!field.access.contains(AFinal)) {
					Context.error('@:constant fields must be final', field.pos);
				}

				var name = field.name;

				builder.hook(Init)
					.addProp({name: name, type: t, optional: e != null})
					.addExpr(if (e == null) {
						macro this.$name = props.$name;
					} else {
						macro if (props.$name != null) this.$name = props.$name;
					});
			default:
				Context.error('Invalid field for :constant', field.pos);
		}
	}
}
