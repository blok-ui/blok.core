package blok;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.core.ClassBuilder;
import blok.core.BuilderHelpers;

using haxe.macro.Tools;

class ServiceBuilder {
  public static function build() {
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
    var registerHooks:Array<Expr> = [];

    builder.addClassMetaHandler({
      name: 'service',
      hook: Init,
      options: [
        { name: 'fallback', optional: false, handleValue: expr -> expr },
        { name: 'id', optional: true }
      ],
      build: function (options:{ fallback:Expr, ?id:String }, builder, fields) {
        fallback = options.fallback;
        if (options.id != null) id = options.id;
      }
    });

    builder.addFieldMetaHandler({
      name: 'provide',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, f) switch f.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @provide vars', f.pos);
          }

          if (!Context.unify(t.toType(), Context.getType('blok.ServiceProvider'))) {
            Context.error('@provide fields must be blok.ServiceProviders', f.pos);
          }

          if (!f.access.contains(AFinal)) {
            Context.error('@provide fields must be final', f.pos);
          }

          var name = f.name;

          registerHooks.push(macro this.$name.register(context));
        default:
          Context.error('@provide may only be used on vars', f.pos);
      }
    });

    builder.addLater(() -> {
      checkFallback(fallback, builder);

      builder.addFields([
        buildFromField(id, fallback, ct, createParams),

        {
          name: 'use',
          pos: (macro null).pos,
          access: [ AStatic, APublic, AInline ],
          kind: FFun({
            params: createParams,
            ret: macro:blok.VNode,
            args: [
              { name: 'build', type: macro:(service:$ct)->blok.VNode }
            ],
            expr: macro {
              return blok.Context.use(context -> build(from(context)));
            }
          })
        }
      ]);
      
      macro class {
        public function register(context:blok.Context) {
          context.set($v{id}, this);
          $b{registerHooks};
        }
      }
    }, After);

    return builder.export();
  }

  public static function buildFromField(id:String, fallback:Expr, type:ComplexType, createParams:Array<TypeParamDecl>):Field {
    return {
      name: 'from',
      pos: (macro null).pos,
      access: [ APublic, AStatic ],
      kind: FFun({
        params: createParams,
        ret: type,
        args: [
          { name: 'context', type: macro:Null<blok.Context>, opt:true },
        ],
        expr: macro {
          if (context == null) return ${fallback};
          var service = context.get($v{id});
          return if (service == null) ${fallback} else service;
        }
      })
    }
  }

  public static function checkFallback(fallback:Expr, builder:ClassBuilder) {
    if (fallback == null) {
      // todo: better warning
      Context.error('Services require a fallback value', builder.cls.pos);
    }
  }
}
