package blok.macro;

import haxe.macro.Expr;
import kit.macro.*;

using kit.macro.Tools;
using blok.macro.Tools;

class AttributeFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':attribute')) {
			parseField(builder, field.getMetadata(':attribute'), field);
		}
	}

	function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
		switch field.kind {
			case FVar(t, e) if (t == null):
				field.pos.error('Expected a type');
			case FVar(t, e):
				var name = field.name;
				var backingName = '__backing_$name';
				var getterName = 'get_$name';

				if (!field.access.contains(AFinal)) {
					field.pos.error(':attribute fields must be final.');
				}

				field.kind = FProp('get', 'never', t);

				// // @:todo This seems to only break things:
				// e = switch e {
				// 	case macro null: macro @:pos(e.pos) new blok.signal.Signal(null);
				// 	default: e;
				// };

				builder.add(macro class {
					@:noCompletion final $backingName:blok.signal.Signal<$t>;

					function $getterName():$t {
						return this.$backingName.get();
					}
				});

				builder.hook(Init)
					.addProp({
						name: name,
						type: t,
						doc: field.doc,
						optional: e != null
					})
					.addExpr(if (e == null) {
						macro this.$backingName = props.$name;
					} else {
						macro @:pos(e.pos) this.$backingName = props.$name ?? $e;
					});
				builder.updateHook()
					.addExpr(if (e == null) {
						macro this.$backingName.set(props.$name);
					} else {
						macro @:pos(e.pos) this.$backingName.set(props.$name ?? $e);
					});
			default:
				meta.pos.error('Invalid field for :attribute');
		}
	}
}
