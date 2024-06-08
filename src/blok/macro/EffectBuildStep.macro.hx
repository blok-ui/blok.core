package blok.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

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
				if (f.args.length != 0) {
					field.pos.error(':effect methods cannot have arguments');
				}

				var name = field.name;
				var expr = f.expr;

				switch f.ret {
					case macro :Void:
						f.expr = macro {
							blok.signal.Observer.track(() -> ${expr});
						}
					default:
						f.expr = macro {
							var cleanup:Null<() -> Void> = null;
							var run = () -> ${expr};
							blok.signal.Observer.track(() -> {
								if (cleanup != null) cleanup();
								@:pos(expr.pos) cleanup = run();
							});
							addDisposable(() -> {
								if (cleanup != null) cleanup();
								cleanup = null;
							});
						}
				}

				builder.hook('setup').addExpr(macro this.$name());
			default:
				field.pos.error(':effect fields must be methods');
		}
	}
}
