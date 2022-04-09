package blok.ui;

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
    var comparisons:Array<Expr> = [];
    var initializers:Array<ObjectField> = [];
    var initHooks:Array<Expr> = [];
    var disposeHooks:Array<Expr> = [];
    var beforeHooks:Array<Expr> = [];
    var afterHooks:Array<Expr> = [];
    var isLazy:Bool = false;

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
      options: [],
      hook: Init,
      build: function (options:{}, builder, fields) {
        if (fields.exists(f -> f.name == 'widgetHasChanged')) {
          Context.error(
            'Cannot use @lazy and a custom widgetHasChanged method',
            fields.find(f -> f.name == 'widgetHasChanged').pos
          );
        }
        isLazy = true;
      }
    });

    builder.addFieldMetaHandler(
      createPropFieldHandler(
        addProp,
        (name, expr) -> initializers.push({ field: name, expr: expr }),
        initHooks.push,
        comparisons.push,
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
                var context = switch findAncestorOfType(blok.context.Provider) {
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
      name: 'after',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          if (func.args.length > 0) {
            Context.error('@after methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          afterHooks.push(macro this.$name());
        default:
          Context.error('@after must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'effect',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          Context.warning(
            '@effect is depreciated and will have undesired behavior. It no longer '
            + 'runs after all rendering is complete, but will run after the Element '
            + 'is built. Use @after instead.'
            + '\n'
            + 'Note: you can hook into the `onChange` observable on a RootElement '
            + 'to get the same behavior @effect used to have.'
            + '\n'
            + 'Important: @effect will be removed in later versions, so migrate to '
            + 'using @after methods instead.',
            field.pos
          );
          if (func.args.length > 0) {
            Context.error('@effect methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          afterHooks.push(macro this.$name());
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
          meta: [
            { name: ':deprecated', pos: (macro null).pos, params: [ macro 'Use `of` instead' ] }
          ],
          kind: FFun({
            params: createParams,
            args: [
              { name: 'props', type: macro:$propType },
              { name: 'key', type: macro:Null<blok.ui.Key>, opt: true }
            ],
            expr: macro return of(props, key),
            ret: macro:blok.ui.Widget
          })
        }
      ]);

      builder.addFields([
        {
          name: 'of',
          access: [ AStatic, APublic, AInline ],
          pos: (macro null).pos,
          meta: [],
          doc: "Create a `blok.ui.ComponentWidget` for this Component.",
          kind: FFun({
            params: createParams,
            args: [
              { name: 'props', type: macro:$propType },
              { name: 'key', type: macro:Null<blok.ui.Key>, opt: true }
            ],
            expr: macro return new blok.ui.ComponentWidget(
              type,
              props,
              widget -> new $clsTp(widget),
              key
            ),
            ret: macro:blok.ui.Widget
          })
        }
      ]);

      if (!builder.fieldExists('new')) {
        builder.add(macro class {
          public function new(widget:blok.ui.ComponentWidget<$propType>) {
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

      if (beforeHooks.length > 0 || updates.length > 0) {
        builder.add(macro class {
          override function performBefore() {
            $b{beforeHooks}
            $b{updates};
          }
        });
      }

      if (initHooks.length > 0) {
        builder.add(macro class {
          override function performInit() {
            $b{initHooks};
          }
        });
      }

      if (afterHooks.length > 0) {
        builder.add(macro class {
          override function performAfter() {
            $b{afterHooks};
          }
        });
      }

      if (isLazy) {
        builder.add(macro class {
          override function widgetHasChanged(current:blok.ui.Widget, previous:blok.ui.Widget) {
            var $PROPS = (cast previous:blok.ui.ComponentWidget<$propType>).props;
            var $INCOMING_PROPS = (cast current:blok.ui.ComponentWidget<$propType>).props;
            var changed:Int = 0;
            $b{comparisons};
            return changed > 0;
          }
        });
      }

      return macro class {
        static public final type = new blok.core.UniqueId();
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
  addCompareHook:(expr:Expr)->Void,
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
      { name: 'comparator', optional: true, handleValue: e -> e }
    ],
    build: function (options:{
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
        var init = e == null
          ? macro $i{INCOMING_PROPS}.$name
          : macro $i{INCOMING_PROPS}.$name == null ? @:pos(e.pos) ${e} : $i{INCOMING_PROPS}.$name;
        
        f.kind = FProp('get', 'never', t, null);

        builder.add(macro class {
          inline function $getName() return (cast widget:blok.ui.ComponentWidget<Dynamic>).props.$name;
        });

        addProp(name, t, e != null);
        addInitializer(name, init);

        addCompareHook(macro switch [ $i{PROPS}.$name, $i{INCOMING_PROPS}.$name ] {
          case [ a, b ] if (!${comparator}):
          default: changed++;
        });

        if (extra != null) extra(f);
      default:
        Context.error('@prop can only be used on vars', f.pos);
    }
  };
}
