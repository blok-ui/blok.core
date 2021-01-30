package blok;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.core.ClassBuilder;
import blok.core.BuilderHelpers;

using haxe.macro.Tools;

class ServiceBuilder {
  public static function autoBuild() {
    var builder = ClassBuilder.fromContext();

    if (builder.isInterface()) return builder.export();

    var cls = builder.cls;
    var id = cls.pack.concat([ cls.name ]).join('.');
    var fallback:Expr = null;
    var createParams = cls.params.length > 0
      ? [ for (p in cls.params) { name: p.name, constraints: BuilderHelpers.extractTypeParams(p) } ]
      : [];
    var ct = (switch Context.getLocalType() {
      case TInst(t, _): haxe.macro.Type.TInst(t, cls.params.map(f -> f.t));
      default: throw 'assert';
    }).toComplexType();

    builder.addClassMetaHandler({
      name: 'service',
      hook: Init,
      options: [
        { name: 'fallback', optional: false, handleValue: expr -> expr },
        { name: 'id', optional: true }
      ],
      build: ( options:{ fallback:Expr, ?id:String }, builder, fields) -> {
        fallback = options.fallback;
        if (options.id != null) id = options.id;
      }
    });

    builder.addLater(() -> {
      if (fallback == null) {
        // todo: better warning
        Context.error('Services requrie a fallback value', builder.cls.pos);
      }

      builder.addFields([
        {
          name: 'from',
          pos: (macro null).pos,
          access: [ APublic, AStatic ],
          kind: FFun({
            params: createParams,
            ret: ct,
            args: [
              { name: 'context', type: macro:blok.core.Context<Dynamic> },
            ],
            expr: macro {
              var service = context.get($v{id});
              return if (service == null) ${fallback} else service;
            }
          })
        }
      ]);
      
      macro class {
        var __register:Array<(context:blok.core.Context<Dynamic>)->Void> = [];
        public function register(context:blok.core.Context<Dynamic>) {
          context.set($v{id}, this);
          // clunky :P
          for (r in __register) r(context);
        }
      }
    }, After);

    return builder.export();
  }
}
