package blok.macro;

import haxe.macro.Expr;
import kit.macro.*;

using Lambda;
using kit.macro.Tools;

typedef SignalFieldBuilderOptions = {
	public final updatable:Bool;
}

class SignalFieldParser implements Parser {
	public final priority:Priority = Normal;

	final options:SignalFieldBuilderOptions;

	public function new(options) {
		this.options = options;
	}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':signal')) {
			parseField(builder, field.getMetadata(':signal'), field);
		}
	}

	function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
		var name = field.name;

		if (!field.access.contains(AFinal)) {
			field.pos.error(':signal fields must be final');
		}

		switch field.kind {
			case FVar(t, e) if (t == null):
				field.pos.error('Expected a type');
			case FVar(t, e):
				var type = switch t {
					case macro :Null<$t>: macro :blok.signal.Signal<Null<$t>>;
					default: macro :blok.signal.Signal<$t>;
				}
				var isOptional = e != null;

				field.kind = FVar(type, switch e {
					case macro null: macro new blok.signal.Signal(null);
					default: e;
				});
				field.meta.push({
					name: ':json',
					params: [
						macro from = value,
						macro to = value.get()
					],
					pos: field.pos
				});

				builder.hook(Init)
					.addProp({
						name: name,
						type: t,
						optional: isOptional
					})
					.addExpr(if (isOptional) {
						macro if (props.$name != null) this.$name = props.$name;
					} else {
						macro this.$name = props.$name;
					});

				if (options.updatable) {
					builder.hook('update').addExpr(if (isOptional) {
						macro if (props.$name != null) this.$name.set(props.$name);
					} else {
						macro this.$name.set(props.$name);
					});
				}
			default:
				meta.pos.error(':signal cannot be used here');
		}
	}
}
