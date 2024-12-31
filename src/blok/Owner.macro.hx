package blok;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

class Owner {
	public static function capture(owner:Expr, expr:Expr) {
		switch expr.expr {
			case EBlock(_):
			default:
				Context.error('Expected a block', expr.pos);
		}

		if (Context.unify(Context.typeof(expr), Context.getType('Void'))) {
			expr = macro {
				$expr;
				null;
			}
		}

		return macro {
			var prev = blok.Owner.setCurrent($owner);
			@:pos(expr.pos) var value = try {
				$expr;
			} catch (e) {
				blok.Owner.setCurrent(prev);
				throw e;
			}
			blok.Owner.setCurrent(prev);
			value;
		}
	}
}
