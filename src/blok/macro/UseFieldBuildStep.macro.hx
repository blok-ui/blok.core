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
			case FVar(t, _) if (!Context.unify(t.toType(), Context.getType('blok.mixin.MixinBase'))):
				field.pos.error(':use fields must be blok Mixins');
			case FVar(t, e):
				field.kind = FProp('get', 'never', t);

				var type = t.toType();
				var ct = type.toComplexType();
				var path:TypePath = switch ct {
					case TPath(p):
						p;
					default:
						field.pos.error('Unexpected type');
						null;
				}

				var getterName = 'get_$name';
				var backingName = '__mixin_$name';
				var error = 'Used $name mixin before setup or after disposal';
				// @todo: This is quite fragile, think up a better way to do things?
				var create = if (e == null) {
					macro @:pos(field.pos) new $path(this, {});
				} else {
					macro blok.signal.Runtime.current().untrack(() -> ${e}(this));
				}

				builder.add(macro class {
					var $backingName:Null<$t> = null;

					function $getterName() {
						blok.debug.Debug.assert(this.$backingName != null, $v{error});
						return this.$backingName;
					}
				});

				builder.setupHook()
					.addExpr(macro @:pos(field.pos) {
						this.$backingName = $create;
						addDisposable(() -> {
							this.$backingName?.dispose();
							this.$backingName = null;
						});
					});
			default:
				meta.pos.error(':use cannot be used here');
		}
	}
}
