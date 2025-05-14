package blok.macro;

import haxe.macro.Expr;
import kit.macro.*;

using blok.macro.Tools;
using kit.macro.Tools;

typedef ObservableFieldBuilderOptions = {
	public final updatable:Bool;
}

class ObservableFieldBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	final options:ObservableFieldBuilderOptions;

	public function new(options) {
		this.options = options;
	}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':observable')) {
			parseField(builder, field.getMetadata(':observable'), field);
		}
	}

	function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
		var name = field.name;

		if (!field.access.contains(AFinal)) {
			field.pos.error(':observable fields must be final');
		}

		switch field.kind {
			case FVar(t, e) if (options.updatable):
				var backingName = '__backing_$name';
				var getterName = 'get_$name';
				var type = switch t {
					case macro :Null<$t>: macro :blok.signal.Signal.ReadOnlySignal<Null<$t>>;
					default: macro :blok.signal.Signal.ReadOnlySignal<$t>;
				}
				var isOptional = e != null;
				var expr = switch e {
					case null: macro null; // Won't actually be used.
					case macro null: macro new blok.signal.Signal.ReadOnlySignal(null);
					default: macro cast($e : blok.signal.Signal.ReadOnlySignal<$t>);
				};

				field.kind = FProp('get', 'never', type);

				builder.add(macro class {
					@:noCompletion final $backingName:blok.signal.Signal<$type>;

					function $getterName():$type return this.$backingName.get();
				});

				var init:Array<Expr> = [
					if (e == null) {
						macro this.$backingName = props.$name;
					} else {
						macro this.$backingName = props.$name ?? $expr;
					}
				];

				builder.hook(Init)
					.addProp({
						name: name,
						type: type,
						optional: isOptional
					})
					.addExpr(macro @:mergeBlock $b{init});
				builder.updateHook()
					.addExpr(if (isOptional) {
						macro if (props.$name != null) this.$backingName.set(props.$name);
					} else {
						macro this.$backingName.set(props.$name);
					});
			case FVar(t, e):
				var type = switch t {
					case macro :Null<$t>: macro :blok.signal.Signal.ReadOnlySignal<Null<$t>>;
					default: macro :blok.signal.Signal.ReadOnlySignal<$t>;
				}

				field.kind = FVar(type, switch e {
					case macro null: macro new blok.signal.Signal(null);
					default: e;
				});

				builder.hook(Init)
					.addProp({
						name: name,
						type: type,
						optional: e != null
					})
					.addExpr(if (e == null) {
						macro this.$name = props.$name;
					} else {
						macro if (props.$name != null) this.$name = props.$name;
					});
			default:
				meta.pos.error(':observable cannot be used here');
		}
	}
}
