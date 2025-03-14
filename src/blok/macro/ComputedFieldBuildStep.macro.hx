package blok.macro;

import haxe.macro.Expr;
import kit.macro.*;

using kit.macro.Tools;

class ComputedFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':computed')) {
			parseField(builder, field.getMetadata(':computed'), field);
		}
	}

	function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
		switch field.kind {
			case FVar(t, e):
				if (t == null) {
					field.pos.error('@:computed field require an explicit type');
				}
				if (e == null) {
					field.pos.error('@:computed fields require an expression');
				}
				if (!field.access.contains(AFinal)) {
					field.pos.error('@:computed fields must be final');
				}

				var name = field.name;
				var access = field.access;
				var createName = '__create_$name';

				field.name = createName;
				field.access = [AInline, AExtern, APrivate];
				field.meta.push({name: ':noCompletion', params: [], pos: (macro null).pos});
				field.kind = FFun({
					args: [],
					ret: macro :blok.signal.Computation<$t>,
					expr: macro return new blok.signal.Computation<$t>(() -> $e)
				});

				builder.addField({
					name: name,
					kind: FVar(macro :blok.signal.Computation<$t>, null),
					access: access,
					pos: meta.pos
				});

				builder.hook(Init).addExpr(macro this.$name = this.$createName());
			default:
				meta.pos.error('Invalid field for :computed');
		}
	}
}
