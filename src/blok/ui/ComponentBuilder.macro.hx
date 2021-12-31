package blok.ui;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.macro.BuilderHelpers.*;
import blok.macro.BuilderHandlers.createMemoFieldHandler;
import blok.macro.BuilderHandlers.createPropFieldHandler;
import blok.macro.ClassBuilder;

using Lambda;
using haxe.macro.Tools;
using blok.macro.BuilderHelpers;

class ComponentBuilder {
  static function build():Array<Field> {
    var builder = ClassBuilder.fromContext();
    var clsTp = builder.getTypePath();
    var clsType = Context.getLocalType().toComplexType();
    var props:Array<Field> = [];
    var updateProps:Array<Field> = [];
    var updates:Array<Expr> = [];
    var initializers:Array<ObjectField> = [];
    var initHooks:Array<Expr> = [];
    var disposeHooks:Array<Expr> = [];
    var beforeHooks:Array<Expr> = [];
    var effectHooks:Array<Expr> = [];

    if (builder.cls.superClass.t.get().module != 'blok.ui.Component') {
      Context.error('Subclassing components is not supported', builder.cls.pos);
    }
    
    function addProp(name:String, type:ComplexType, isOptional:Bool) {
      props.push({
        name: name,
        kind: FVar(type, null),
        access: [ APublic ],
        meta: isOptional ? [ OPTIONAL_META ] : [],
        pos: (macro null).pos
      });
      updateProps.push({
        name: name,
        kind: FVar(type, null),
        access: [ APublic ],
        meta: [ OPTIONAL_META ],
        pos: (macro null).pos
      });
    }

    builder.addClassMetaHandler({
      name: 'lazy',
      hook: After,
      options: [],
      build: function (options:{}, builder, fields) {
        if (fields.exists(f -> f.name == 'shouldComponentRender')) {
          Context.error(
            'Cannot use @lazy and a custom shouldComponentRender method',
            fields.find(f -> f.name == 'shouldComponentRender').pos
          );
        }
        builder.add(macro class {
          override function shouldComponentRender():Bool {
            return __currentRevision > __lastRevision;
          }
        });
      } 
    });

    builder.addFieldMetaHandler(
      createPropFieldHandler(
        addProp,
        (name, expr) -> initializers.push({ field: name, expr: expr }),
        initHooks.push,
        updates.push
      )
    );

    builder.addFieldMetaHandler({
      name: 'use',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, field) switch field.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @use vars', field.pos);
          }

          if (e != null) {
            Context.error('@use vars cannot be initialized', field.pos);
          }

          var path = t.toType().getPathExprFromType();
          var name = field.name;
          var getter = 'get_$name';
          var backingName = '__computedValue_$name';

          field.kind = FProp('get', 'never', t, null);

          builder.add(macro class {
            var $backingName:$t = null;

            function $getter() {
              if (this.$backingName == null) {
                var context = switch findParentOfType(blok.context.Provider) {
                  case None: new blok.context.Context();
                  case Some(provider): provider.getContext();
                }
                @:pos(field.pos) this.$backingName = (${path}:blok.context.ServiceResolver<$t>).from(context);
              }
              return this.$backingName;
            } 
          });

          updates.push(macro this.$backingName = null);
        default:
          Context.error('@use can only be used on vars', field.pos);
      }
    });
    
    builder.addFieldMetaHandler({
      name: 'update',
      hook: After,
      options: [],
      build: function (options:{}, builder, field) switch field.kind {
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
                updateComponentProperties(data);
                if (shouldComponentRender()) invalidateWidget();
            }
          }
        default:
          Context.error('@update must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler(
      createMemoFieldHandler(e -> updates.push(e))
    );

    builder.addFieldMetaHandler({
      name: 'init',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          if (func.args.length > 0) {
            Context.error('@init methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          initHooks.push(macro @:pos(field.pos) inline this.$name());
        default:
          Context.error('@init must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'dispose',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
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

    builder.addFieldMetaHandler({
      name: 'before',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          if (func.args.length > 0) {
            Context.error('@before methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          beforeHooks.push(macro inline this.$name());
        default:
          Context.error('@before must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'effect',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          if (func.args.length > 0) {
            Context.error('@effect methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          effectHooks.push(macro inline this.$name());
        default:
          Context.error('@effect must be used on a method', field.pos);
      }
    });

    // Makes functions return a VNodeResult to ease writing Components.
    function ensureReturnTypes(name:String) {
      var method = builder.getField(name);
      if (method == null) return;
      switch method.kind {
        case FFun(f):
          if (f.ret == null) {
            f.ret = macro:blok.ui.VNodeResult;
          }
        default: 
          throw 'assert';
      }
    }

    builder.addLater(() -> {
      var propType = TAnonymous(props);
      var updateType = TAnonymous(updateProps);
      var createParams = builder.cls.params.length > 0
        ? [ for (p in builder.cls.params) { name: p.name, constraints: extractTypeParams(p) } ]
        : [];

      ensureReturnTypes('render');

      builder.addFields([
        {
          name: 'node',
          access: [ AStatic, APublic, AInline ],
          pos: (macro null).pos,
          meta: [],
          kind: FFun({
            params: createParams,
            args: [
              { name: 'props', type: macro:$propType },
              { name: 'key', type: macro:Null<blok.ui.Key>, opt: true }
            ],
            expr: macro return new blok.ui.VComponent(__type, props, props -> new $clsTp(props), key),
            ret: macro:blok.ui.VNode
          })
        }
      ]);

      if (!builder.fieldExists('new')) {
        builder.add(macro class {
          public function new($INCOMING_PROPS:$propType) {
            __initComponentProps($i{INCOMING_PROPS});
          }
        });
      } else {
        Context.error(
          'You cannot define a constructor for components -- blok will '
          + 'generate one for you. If you need initialization logic, use '
          + '@init meta on a method.', 
          builder.getField('new').pos
        );
      }

      return macro class {
        @:noCompletion var $PROPS:$propType;

        @:noCompletion
        static public final __type = new blok.ui.WidgetType();

        public function getWidgetType() return __type;

        inline function __initComponentProps($INCOMING_PROPS:$propType) {
          this.$PROPS = ${ {
            expr: EObjectDecl(initializers),
            pos: (macro null).pos
          } };
        }

        override function __initHooks() {
          $b{initHooks}
        }

        function __beforeHooks() {
          $b{beforeHooks}
        }

        function runComponentEffects() {
          $b{effectHooks}
        }

        public function updateComponentProperties(props:Dynamic) {
          switch __status {
            case WidgetUpdating:
              // throw new blok.exception.ComponentIsRenderingException(this);
            case _:
          }
          
          var $INCOMING_PROPS:$updateType = cast props;
          __lastRevision = __currentRevision;
          $b{updates};
        }

        override function dispose() {
          $b{disposeHooks};
          super.dispose();
        }
      }
    });
    
    return builder.export();
  }
}
