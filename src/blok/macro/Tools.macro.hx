package blok.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.ClassBuilder;

inline function setupHook(builder:ClassBuilder) {
	return builder.hook('setup');
}

inline function updateHook(builder:ClassBuilder) {
	return builder.hook('update');
}

function prepareForDisplay(e:Expr, ?kind:DisplayKind) {
	if (Context.containsDisplayPosition(e.pos)) {
		return {expr: EDisplay(e, kind ?? DKMarked), pos: e.pos};
	}
	return e;
}
