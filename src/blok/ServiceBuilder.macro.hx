package blok;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.tools.ClassBuilder;

using haxe.macro.Tools;
using blok.tools.BuilderHelpers;

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
    var useHooks:Array<Expr> = [];

    builder.addClassMetaHandler({
      name: 'service',
      hook: Init,
      options: [
        { name: 'fallback', optional: true, handleValue: expr -> expr },
        { name: 'isOptional', optional: true },
        { name: 'id', optional: true }
      ],
      build: function (options:{ fallback:Null<Expr>, isOptional:Null<Bool>, ?id:String }, builder, fields) {
        fallback = options.fallback == null
          ? options.isOptional ? macro null : null
          : options.fallback ;
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

    builder.addFieldMetaHandler(
      createUseFieldHandler(useHooks)
    );

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
          $b{useHooks};
        }
      }
    }, After);

    return builder.export();
  }

  public static function createUseFieldHandler(useHooks:Array<Expr>):FieldMetaHandler<{}> {
    return {
      name: 'use',
      hook: Normal,
      options: [
        // { name: 'isOptional', optional: true }
      ],
      build: function (options:{}, builder, f) switch f.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @use vars', f.pos);
          }

          var path = t.toType().getPathExprFromType();
          var name = f.name;
          var getter = 'get_$name';
          var backingName = '__computedValue_$name';

          if (!Context.unify(Context.typeof(path), Context.getType('blok.ServiceResolver'))) {
            Context.error(
              '@use fileds must be blok.ServiceResolvers',
              f.pos
            );
          }

          f.kind = FProp('get', 'never', t, null);

          builder.add(macro class {
            var $backingName:Null<$t> = null;

            function $getter() {
              if (this.$backingName == null) {
                // Todo: not sure about how to handle this error.
                throw 'Tried to access the `@use` field ' + $v{name} + ', but no service '
                  + 'was available. Generally, this means that you accessed this field '
                  + 'before it was registered with a Context.';
              }
              return this.$backingName;
            }
          });
          
          useHooks.push(macro this.$backingName = ${path}.from(context));
        default:
          Context.error('@use may only be used on vars', f.pos);
      }
    };
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
          { name: 'context', type: macro:blok.Context, opt:true },
        ],
        expr: macro {
          var service = context.get($v{id});
          if (service == null) {
            service = ${fallback};
            service.register(context); 
          } 
          return service;
        }
      })
    }
  }

  public static function checkFallback(fallback:Expr, builder:ClassBuilder) {
    if (fallback == null) { 
      Context.error(
        'Services require a fallback value, set via `@service(fallback = ...)`.', 
        builder.cls.pos
      );
    }
    
    switch fallback {
      case macro null:
        Context.warning(
          'Services should NOT fallback to null. If you\'re sure you want this '
          + 'service to be optional, use `@service(isOptional)`.',
          fallback.pos
        );
      default: 
    }
  }
}
