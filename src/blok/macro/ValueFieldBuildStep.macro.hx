package blok.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import kit.macro.*;

class ValueFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':constant')) {
			Context.warning('Replace :constant with :value', field.pos);
		}

		for (field in builder.findFieldsByMeta(':value')) {
			parseField(builder, field);
		}
	}

	function parseField(builder:ClassBuilder, field:Field) {
		switch field.kind {
			case FVar(t, e):
				if (!field.access.contains(AFinal)) {
					Context.error('@:value fields must be final', field.pos);
				}

				var name = field.name;

				builder.hook(Init)
					.addProp({
						name: name,
						type: t,
						doc: field.doc,
						optional: e != null
					})
					.addExpr(if (e == null) {
						macro this.$name = props.$name;
					} else {
						macro if (props.$name != null) this.$name = props.$name;
					});
			default:
				Context.error('Invalid field for :value', field.pos);
		}
	}
}
