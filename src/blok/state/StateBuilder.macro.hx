package blok.state;

import blok.context.ServiceBuilder;
import haxe.macro.Expr;
import haxe.macro.Context;
import blok.macro.BuilderHelpers.*;
import blok.macro.BuilderHandlers.createMemoFieldHandler;
import blok.macro.BuilderHandlers.createPropFieldHandler;
import blok.macro.ClassBuilder;

using haxe.macro.Tools;
using blok.macro.BuilderHelpers;

class StateBuilder {
  public static function build() {
    var builder = ClassBuilder.fromContext();
    var cls = builder.cls;
    var clsName = cls.pack.concat([cls.name]).join('.');
    var clsTp = builder.getTypePath();
    var props:Array<Field> = [];
    var updateProps:Array<Field> = [];
    var updates:Array<Expr> = [];
    var initializers:Array<ObjectField> = [];
    var subStates:Array<Expr> = [];
    var initHooks:Array<Expr> = [];
    var disposeHooks:Array<Expr> = [];
    var registerHooks:Array<Expr> = [];
    var useHooks:Array<Expr> = [];
    var id = clsName;
    var fallback:Expr = null;
    var fallbackOptional:Bool = false;

    function addProp(name:String, type:ComplexType, isOptional:Bool, isUpdating:Bool) {
      props.push({
        name: name,
        kind: FVar(type, null),
        access: [ APublic ],
        meta: isOptional ? [ OPTIONAL_META ] : [],
        pos: (macro null).pos
      });
      if (isUpdating) updateProps.push({
        name: name,
        kind: FVar(type, null),
        access: [ APublic ],
        meta: [ OPTIONAL_META ],
        pos: (macro null).pos
      });
    }

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
        if (options.isOptional) fallbackOptional = true;
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

          // // This check is causing issues with compiling, so I've turned it off.
          // // Actually it might be a good idea NOT to do unification checks in our builders,
          // // as we can end up checking types that are still getting processed
          // // by macros.
          // if (!Context.unify(t.toType(), Context.getType('blok.context.ServiceProvider'))) {
          //   Context.error('@provide fields must be blok.context.ServiceProviders', f.pos);
          // }

          var name = f.name;
          var getName = 'get_${name}';
          var init = e == null
            ? macro $i{INCOMING_PROPS}.$name
            : macro $i{INCOMING_PROPS}.$name == null ? ${e} : $i{INCOMING_PROPS}.$name;
          
          f.kind = FProp('get', 'never', t, null);
          addProp(name, t, e != null, true);
          builder.add(macro class {
            inline function $getName() return $i{PROPS}.$name;
          });

          initializers.push({
            field: name,
            expr: init
          });

          registerHooks.push(macro @:pos(f.pos) (this.$name:blok.context.ServiceProvider).register(context));
        default:
          Context.error('@provide may only be used on vars', f.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'dispose',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, field) switch field.kind {
        case FFun(func):
          if (func.args.length > 0) {
            Context.error('@dispose methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          disposeHooks.push(macro @:pos(field.pos) inline this.$name());
        default:
          Context.error('@dispose must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler(
      createPropFieldHandler(
        (name, type, isOptional) -> addProp(name, type, isOptional, true),
        (name, expr) -> initializers.push({ field: name, expr:expr }),
        initHooks.push,
        updates.push,
        f -> if (!f.access.contains(APublic)) {
          f.access.push(APublic);
        }
      )
    );

    builder.addFieldMetaHandler({
      name: 'update',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          if (func.ret != null) {
            Context.error('@update functions should not define their return type manually', field.pos);
          }
          var updatePropsRet = TAnonymous(updateProps);
          var e = func.expr;

          func.ret = macro:Void;
          
          func.expr = macro {
            inline function closure():Null<$updatePropsRet> ${e};
            switch closure() {
              case null:
              case data:
                __updateProps(data);
                if (__currentRevision > __lastRevision) {
                  __observable.notify();
                }
            }
          }
        default:
          Context.error('@update must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler(
      ServiceBuilder.createUseFieldHandler(useHooks)
    );

    builder.addFieldMetaHandler(
      ServiceBuilder.createInitFieldHandler(initHooks)
    );

    builder.addFieldMetaHandler(
      createMemoFieldHandler(e -> updates.push(e))
    );

    builder.addLater(() -> {
      ServiceBuilder.checkFallback(fallback, fallbackOptional, builder);

      var propType = TAnonymous(props);
      var updatePropsType = TAnonymous(updateProps);
      var type = Context.getLocalType();
      var createParams = cls.params.length > 0
        ? [ for (p in cls.params) { name: p.name, constraints: BuilderHelpers.extractTypeParams(p) } ]
        : [];
      var ct = (switch type {
        case TInst(t, _): haxe.macro.Type.TInst(t, cls.params.map(f -> f.t));
        default: throw 'assert';
      }).toComplexType();
      var providerFactory = macro:(context:blok.context.Context)->blok.ui.Widget;
      var observerFactory = macro:(data:$ct)->blok.ui.Widget;

      builder.addFields([
        {
          name: 'provide',
          pos: (macro null).pos,
          access: [ APublic, AStatic ],
          kind: FFun({
            params: createParams,
            ret: macro:blok.ui.Widget,
            args: [
              { name: 'props', type: macro:$propType },
              { name: 'build', type: macro:$providerFactory }
            ],
            expr: macro {
              var state = new $clsTp(props);
              return blok.context.Provider.node({
                service: state,
                build: build
              });
            }
          })
        },

        {
          name: 'observe',
          pos: (macro null).pos,
          access: [ APublic, AStatic, AInline ],
          kind: FFun({
            params: createParams,
            ret: macro:blok.ui.Widget,
            args: [
              { name: 'context', type: macro:blok.context.Context },
              { name: 'build', type: macro:$observerFactory }
            ],
            expr: macro return from(context).getObservable().render(build)
          })
        },

        {
          name: 'use',
          pos: (macro null).pos,
          access: [ APublic, AStatic, AInline ],
          kind: FFun({
            params: createParams,
            ret: macro:blok.ui.Widget,
            args: [
              { name: 'build', type: macro:$observerFactory }
            ],
            expr: macro {
              return blok.context.Context.use(context -> observe(context, build));
            }
          })
        },

        ServiceBuilder.buildFromField(id, fallback, ct, createParams)
      ]);

      return macro class {
        var $PROPS:$propType;
        var __currentRevision:Int = 0;
        var __lastRevision:Int = 0;
        var __disposables:Array<blok.core.Disposable> = [];
        final __observable:blok.state.Observable<$ct>;
        
        public function new($INCOMING_PROPS:$propType) {
          __observable = new blok.state.Observable(this);
          addDisposable(__observable);

          this.$PROPS = ${ {
            expr: EObjectDecl(initializers),
            pos: (macro null).pos
          } };
        }

        public function getObservable():blok.state.Observable<$ct> {
          return __observable;
        }

        @:noCompletion
        function __updateProps($INCOMING_PROPS:$updatePropsType) {
          __lastRevision = __currentRevision;
          $b{updates};
        }

        public function addDisposable(disposable:blok.core.Disposable):Void {
          __disposables.push(disposable);
        }

        public function dispose() {
          for (d in __disposables) d.dispose();
          __disposables = [];
          $b{disposeHooks};
        }

        public function register(context:blok.context.Context) {
          context.set($v{id}, this);
          $b{registerHooks};
          $b{useHooks};
          $b{initHooks};
        }
      };
    });
    
    return builder.export();
  }
}
