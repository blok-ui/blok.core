package blok;

import blok.VNodeType.getUniqueTypeId;
import haxe.macro.Context;
import haxe.macro.Expr;
import blok.tools.BuilderHelpers.*;
import blok.tools.ClassBuilder;

using Lambda;
using haxe.macro.Tools;

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
    var dontGenerateType:Bool = false;
    
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
      name: 'component',
      hook: Init,
      options: [
        { name: 'dontGenerateType', optional: true }
      ],
      build: function (options:{ ?dontGenerateType:Bool }, builder, fields) {
        if (options.dontGenerateType == true) dontGenerateType = true;
        // todo: other config?
      }
    });

    builder.addClassMetaHandler({
      name: 'lazy',
      hook: After,
      options: [],
      build: function (options:{}, builder, fields) {
        if (fields.exists(f -> f.name == 'shouldComponentUpdate')) {
          Context.error(
            'Cannot use @lazy and a custom shouldComponentUpdate method',
            fields.find(f -> f.name == 'shouldComponentUpdate').pos
          );
        }
        builder.add(macro class {
          override function shouldComponentUpdate():Bool {
            return __currentRevision > __lastRevision;
          }
        });
      } 
    });
    
    builder.addFieldMetaHandler({
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
            inline function $getName() return $i{PROPS}.$name;
          });

          addProp(name, t, e != null);
          initializers.push({
            field: name,
            expr: init
          });
          
          if (onChange.length > 0 ) {
            initHooks.push(macro {
              var previous = null;
              var value = __props.$name;
              $b{onChange};
            });
          }

          updates.push(macro {
            if (Reflect.hasField($i{INCOMING_PROPS}, $v{name})) {
              switch [
                $i{PROPS}.$name, 
                $i{INCOMING_PROPS}.$name 
              ] {
                case [ a, b ] if (!${comparator}):
                  // noop
                case [ previous, value ]:
                  __currentRevision++;
                  $i{PROPS}.$name = value;
                  $b{onChange}
              }
            }
          });
          
        default:
          Context.error('@prop can only be used on vars', f.pos);
      }
    });

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

          if (
            !Context.unify(t.toType(), Context.getType('blok.Service'))
            && !Context.unify(t.toType(), Context.getType('blok.State'))
          ) {
            Context.error('@use must be a blok.Service or a blok.State', field.pos);
          }

          var clsName = t.toType().toString();
          if (clsName.indexOf('<') >= 0) clsName = clsName.substring(0, clsName.indexOf('<'));
          
          var path = clsName.split('.'); // is there a better way
          var name = field.name;
          var getter = 'get_$name';
          var backingName = '__computedValue_$name';
          
          field.kind = FProp('get', 'never', t, null);

          builder.add(macro class {
            var $backingName:$t = null;

            function $getter() {
              if (this.$backingName == null) {
                var context = switch findInheritedComponentOfType(blok.Provider) {
                  case None: null;
                  case Some(provider): provider.getContext();
                }
                this.$backingName = $p{path}.from(context);
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
            if (__isRendering) {
              throw new blok.exception.ComponentIsRenderingException(this);
            }
            inline function closure():blok.UpdateMessage<$updatePropsRet> ${e};
            switch closure() {
              case None | null:
              case Update:
                updateComponent();
              case UpdateState(data): 
                updateComponentProperties(data);
                if (shouldComponentUpdate()) updateComponent();
              case UpdateStateSilent(data):
                updateComponentProperties(data);
            }
          }
        default:
          Context.error('@update must be used on a method', field.pos);
      }
    });

    builder.addFieldMetaHandler(createMemoFieldHandler(e -> updates.push(e)));

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

    builder.addLater(() -> {
      var propType = TAnonymous(props);
      var updateType = TAnonymous(updateProps);
      var createParams = builder.cls.params.length > 0
        ? [ for (p in builder.cls.params) { name: p.name, constraints: extractTypeParams(p) } ]
        : [];

      if (!dontGenerateType) {
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
                { name: 'key', type: macro:Null<blok.Key>, opt: true }
              ],
              expr: macro return new blok.VComponent(__type, props, props -> new $clsTp(props), key),
              ret: macro:blok.VNode
            })
          }
        ]);

        builder.add(macro class {
          @:noCompletion
          static public final __type = blok.VNodeType.getUniqueTypeId();
        });
      }

      if (!builder.fieldExists('new')) {
        builder.add(macro class {
          public function new($INCOMING_PROPS:$propType) {
            __initComponentProps($i{INCOMING_PROPS});
          }
        });
      } else if (!dontGenerateType) {
        Context.error(
          'Cannot use a custom constructor unless `@component(dontGenerateType)` is set', 
          builder.getField('new').pos
        );
      }

      if (!dontGenerateType) {
        builder.add(macro class {
          public function getComponentType() return __type;
        });
      }

      return macro class {
        @:noCompletion var $PROPS:$propType;

        inline function __initComponentProps($INCOMING_PROPS:$propType) {
          this.$PROPS = ${ {
            expr: EObjectDecl(initializers),
            pos: (macro null).pos
          } };
        }

        function __runInitHooks() {
          $b{initHooks}
        }

        function __runBeforeHooks() {
          $b{beforeHooks}
        }

        function __runEffectHooks() {
          $b{effectHooks}
        }

        public function updateComponentProperties(props:Dynamic) {
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