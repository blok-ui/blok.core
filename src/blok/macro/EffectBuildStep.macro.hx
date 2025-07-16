package blok.macro;

import haxe.macro.Expr;
import kit.macro.*;

using blok.macro.Tools;
using kit.macro.Tools;

class EffectBuildStep implements BuildStep {
	public final priority:Priority = Normal;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		for (field in builder.findFieldsByMeta(':effect')) {
			parseEffectMethod(field, builder);
		}
	}

	function parseEffectMethod(field:Field, builder:ClassBuilder) {
		switch field.kind {
			case FFun(f):
				if (field.access.contains(AStatic)) {
					field.pos.error(':effect fields cannot be static');
				}
				if (!field.access.contains(AInline)) {
					field.access.push(AInline);
				}

				var name = field.name;
				var call:Expr = switch f.args {
					case []: macro this.$name();
					case args:
						var apply:Array<Expr> = [for (arg in args) {
							switch arg.meta {
								case [{name: ':primitive'}]:
									macro investigate().getPrimitive();
								default:
									field.pos.error('Invalid argument. Only args marked with @:primitive are allowed now.');
									macro null;
							}
						}];
						macro this.$name($a{apply});
				}

				builder.setupHook().addExpr(switch f.ret {
					case macro :Void:
						macro blok.signal.Observer.track(() -> ${call});
					default:
						macro {
							var cleanup:Null<() -> Void> = null;
							blok.signal.Observer.track(() -> {
								if (cleanup != null) cleanup();
								cleanup = ${call};
							});
							addDisposable(() -> {
								if (cleanup != null) cleanup();
								cleanup = null;
							});
						}
				});
			default:
				field.pos.error(':effect fields must be methods');
		}
	}
}
