package blok.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;
using Lambda;
using haxe.macro.Tools;
using kit.Hash;

function getField(t:TypeDefinition, name:String, ?pos:Position):Result<Field, haxe.macro.Expr.Error> {
  return switch t.fields.find(f -> f.name == name) {
    case null: Error(new haxe.macro.Expr.Error('Field $name was not found', pos ?? Context.currentPos()));
    case field: Ok(field);
  }
}

function toTypeParamDecl(params:Array<TypeParameter>) {
  return params.map(p -> ({
    name: p.name,
    constraints: extractTypeParams(p)
  }:TypeParamDecl));
}

function withPos(field:Field, position:Position) {
  field.pos = position;
  return field;
}

function applyParameters(field:Field, params:Array<TypeParamDecl>) {
  switch field.kind {
    case FFun(f):
      f.params = params;
    default:
      // todo
  }
  return field;
}

function typeExists(name:String) {
  try {
    return Context.getType(name) != null;
  } catch (e:String) {
    return false;
  }
}

function typePathExists(path:TypePath) {
  return typeExists(typePathToString(path));
}

function typePathToString(path:TypePath) {
  return path.pack.concat([path.name]).join('.');
}

function parseAsType(name:String):ComplexType {
  return switch Context.parse('(null:${name})', Context.currentPos()) {
    case macro(null : $type): type;
    default: null;
  }
}

function resolveComplexType(expr:Expr):ComplexType {
  return switch expr.expr {
    case ECall(e, params):
      var tParams = params.map(param -> resolveComplexType(param).toString()).join(',');
      parseAsType(resolveComplexType(e).toString() + '<' + tParams + '>');
    default: switch Context.typeof(expr) {
      case TType(_, _):
        parseAsType(expr.toString());
      default:
        Context.error('Invalid expression', expr.pos);
        null;
    }
  }
}

function stringifyTypeForClassName(type:haxe.macro.Type):String {
  return switch type {
    // Attempt to use human-readable names if possible
    case TInst(t, []): 
      type.toString().replace('.', '_');
    case TInst(t, params):
      t.toString().replace('.', '_') + '__' + params.map(stringifyTypeForClassName).join('_'); 
    default: 
      // Fallback to using a hash.
      type.toString().hash();
  }
}

function extractTypeParams(tp:TypeParameter) {
  return switch tp.t {
    case TInst(kind, _): switch kind.get().kind {
      case KTypeParameter(constraints): constraints.map(t -> t.toComplexType());
      default: [];
    }
    default: [];
  }
}