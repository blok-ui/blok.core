package blok.parse;

import haxe.macro.Expr;

using StringTools;
using haxe.macro.Tools;

function isComponentName(name:String) {
	if (name.contains('.')) {
		var last = name.split('.').pop();
		return last.charAt(0).toUpperCase() == last.charAt(0);
	}
	return name.charAt(0).toUpperCase() == name.charAt(0);
}

inline function toPath(name:String):Array<String> {
	return name.split('.');
}

function toExpr(name:Located<String>):Expr {
	return name.value.split('.').toFieldExpr(name.pos);
}

function toPathString(parts:Array<Located<String>>):String {
	return parts.map(part -> part.value).join('.');
}

function getLast(parts:Array<Located<String>>) {
	return parts[parts.length - 1];
}

function toPathExpr(parts:Array<Located<String>>):Expr {
	var expr:Null<Expr> = null;
	for (part in parts) {
		if (expr == null)
			expr = {expr: EConst(CIdent(part.value)), pos: part.pos};
		else
			expr = {expr: EField(expr, part.value), pos: part.pos};
	}
	return expr;
}
