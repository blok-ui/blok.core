package blok.debug;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.ExprTools;
using haxe.macro.Tools;

function warn(e) {
	if (Compiler.getConfiguration().debug) {
		// @todo: Come up with a better way to trace things
		return macro @:pos(e.pos) trace($e);
	}
	return macro null;
}

function error(message:ExprOf<String>) {
	var type = Context.getLocalType();
	if (Context.unify(type, (macro :blok.View).toType())) {
		return macro @:pos(message.pos) throw new blok.BlokException.BlokComponentException($message, this);
	}
	return macro @:pos(message.pos) throw new blok.BlokException($message);
}

function assert(condition:Expr, ?message:Expr):Expr {
	if (!Compiler.getConfiguration().debug) {
		return macro null;
	}

	switch message {
		case macro null:
			var str = 'Failed assertion: ' + condition.toString();
			message = macro @:pos(condition.pos) $v{str};
		default:
	}

	var err = error(message);
	return macro @:pos(condition.pos) if (!$condition) {
		$err;
	}
}
