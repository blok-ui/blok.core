package blok.framework;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.macro.BuilderHelpers.*;
import blok.macro.BuilderHandlers.createMemoFieldHandler;
// import blok.macro.BuilderHandlers.createPropFieldHandler;
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

    if (builder.cls.superClass.t.get().module != 'blok.framework.Component') {
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
          var backingName = 'computedValue_$name';

          field.kind = FProp('get', 'never', t, null);

          builder.add(macro class {
            var $backingName:$t = null;

            function $getter() {
              if (this.$backingName == null) {
                var context = switch findAncestorOfType(blok.framework.context.Provider) {
                  case None: new blok.framework.context.Context();
                  case Some(provider): provider.getContext();
                }
                @:pos(field.pos) this.$backingName = (${path}:blok.framework.context.ServiceResolver<$t>).from(context);
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
              case props: updateWidgetAndInvalidateElement(props);
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
          effectHooks.push(macro effects.register(this.$name));
        default:
          Context.error('@effect must be used on a method', field.pos);
      }
    });

    builder.addLater(() -> {
      var propType = TAnonymous(props);
      var updateType = TAnonymous(updateProps);
      var createParams = builder.cls.params.length > 0
        ? [ for (p in builder.cls.params) { name: p.name, constraints: extractTypeParams(p) } ]
        : [];

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
              { name: 'key', type: macro:Null<blok.framework.Key>, opt: true }
            ],
            expr: macro return new blok.framework.ComponentWidget(type, props, widget -> new $clsTp(widget), key),
            ret: macro:blok.framework.Widget
          })
        }
      ]);

      if (!builder.fieldExists('new')) {
        builder.add(macro class {
          public function new(widget:blok.framework.ComponentWidget<$propType>) {
            super(widget);
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

      if (disposeHooks.length > 0) {
        builder.add(macro class {
          override function dispose() {
            super.dispose();
            $b{disposeHooks};
          }
        });
      }

      if (beforeHooks.length > 0) {
        builder.add(macro class {
          override function performRender() {
            $b{beforeHooks}
            return super.performRender();
          }
        });
      }

      if (initHooks.length > 0) {
        builder.add(macro class {
          override function mount(parent, ?slot) {
            $b{initHooks};
            super.mount(parent, slot);
          }
        });
      }

      if (effectHooks.length > 0) {
        builder.add(macro class {
          override function performBuild() {
            super.performBuild();
            platform.scheduleEffects(effects -> $b{effectHooks});
          }
        });
      }

      return macro class {
        @:noCompletion
        static public final type = new blok.core.UniqueId();

        @:noCompletion
        function updateWidget(props:Dynamic) {
          var widget:blok.framework.ComponentWidget<$propType> = cast this.widget;
          var $PROPS = widget.props;
          var $INCOMING_PROPS:$updateType = cast props;
          lastRevision = currentRevision;

          $b{updates};

          if (currentRevision > lastRevision) {
            this.widget = widget.withProperties($i{PROPS});
          }
        }
      }
    });
    
    return builder.export();
  }
}

// @todo: temp while we're working on the API
function createPropFieldHandler(
  addProp:(name:String, type:ComplexType, isOptional:Bool)->Void,
  addInitializer:(name:String, expr:Expr)->Void,
  addInitHook:(expr:Expr)->Void,
  addUpdateHook:(expr:Expr)->Void,
  ?extra:(f:Field)->Void
):FieldMetaHandler<{ 
  ?onChange:Expr,
  ?comparator:Expr
}> {
  return {
    name: 'prop',
    hook: Normal,
    options: [
      { name: 'comparator', optional: true, handleValue: e -> e },
      { name: 'onChange', optional: true, handleValue: e -> e }
    ],
    build: function (options:{ 
      ?onChange:Expr,
      ?comparator:Expr 
    }, builder, f) switch f.kind {
      case FVar(t, e):
        if (t == null) {
          Context.error('Types cannot be inferred for @prop vars', f.pos);
        }

        var name = f.name;
        var getName = 'get_${name}';
        var comparator = options.comparator != null
          ? macro (@:pos(options.comparator.pos) ${options.comparator})
          : macro (a != b);
        var onChange:Array<Expr> = options.onChange != null
          ? [ macro @:pos(options.onChange.pos) ${options.onChange} ]
          : [];
        var init = e == null
          ? macro $i{INCOMING_PROPS}.$name
          : macro $i{INCOMING_PROPS}.$name == null ? @:pos(e.pos) ${e} : $i{INCOMING_PROPS}.$name;
        
        f.kind = FProp('get', 'never', t, null);

        builder.add(macro class {
          inline function $getName() return (cast widget:blok.framework.ComponentWidget<Dynamic>).props.$name;
        });

        addProp(name, t, e != null);
        addInitializer(name, init);
        
        if (onChange.length > 0 ) {
          addInitHook(macro {
            var prev = null;
            var value = props.$name;
            $b{onChange};
          });
        }

        addUpdateHook(macro {
          if (Reflect.hasField($i{INCOMING_PROPS}, $v{name})) {
            switch [
              $i{PROPS}.$name, 
              $i{INCOMING_PROPS}.$name 
            ] {
              case [ a, b ] if (!${comparator}):
                // noop
              case [ prev, value ]:
                currentRevision++;
                $i{PROPS}.$name = value;
                $b{onChange}
            }
          }
        });

        if (extra != null) extra(f);
      default:
        Context.error('@prop can only be used on vars', f.pos);
    }
  };
}
