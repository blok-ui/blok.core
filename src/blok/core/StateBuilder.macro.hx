package blok.core;

import haxe.macro.Expr;
import haxe.macro.Context;
import blok.core.BuilderHelpers.*;

using haxe.macro.Tools;
using blok.core.BuilderHelpers;

class StateBuilder {
  public static function autoBuild(e:Expr) {
    var nodeType = e.extractBuildCt();
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
    var id = clsName;

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
    
    builder.addFieldMetaHandler({
      name: 'provide',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, f) switch f.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @provide vars', f.pos);
          }

          if (!Context.unify(t.toType(), Context.getType('blok.Service'))) {
            Context.error('@provide fields must be blok.Services', f.pos);
          }

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

          initHooks.push(macro __register.push(context -> this.$name.register(context)));

          if (Context.unify(t.toType(), Context.getType('blok.Disposable'))) {
            disposeHooks.push(macro this.$name.dispose());
          }
        default:
          Context.error('@provide may only be used on vars', f.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'prop',
      hook: Normal,
      options: [],
      build: function (options:{}, builder, f) switch f.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @prop vars', f.pos);
          }

          if (!f.access.contains(APublic)) {
            f.access.remove(APrivate);
            f.access.push(APublic);
          }

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
          updates.push(macro {
            if ($i{INCOMING_PROPS}.$name != null) {
              switch [
                $i{PROPS}.$name, 
                $i{INCOMING_PROPS}.$name 
              ] {
                case [ a, b ] if (a == b):
                  // noop
                case [ current, value ]:
                  this.__dirty = true;
                  this.$PROPS.$name = value;
              }
            }
          });
        default:
          Context.error('@prop can only be used on vars', f.pos);
      }
    });

    builder.addFieldMetaHandler({
      name: 'init',
      hook: After,
      options: [],
      build: function(_, builder, field) switch field.kind {
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
            inline function closure():blok.core.UpdateMessage<$updatePropsRet> ${e};
            switch closure() {
              case None | null:
              case Update:
                __signal.dispatch(this);
              case UpdateState(data):
                __updateProps(data);
                if (__dirty) {
                  __dirty = false;
                  __signal.dispatch(this);
                }
              case UpdateStateSilent(data):
                __updateProps(data);
                __dirty = false;
            }
          }
        default:
          Context.error('@update must be used on a method', field.pos);
      }
    });

    builder.addLater(() -> {
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
      var providerFactory = macro:(context:blok.core.Context<$nodeType>)->blok.core.VNode<$nodeType>;
      var observerFactory = macro:(data:$ct)->blok.core.VNode<$nodeType>;

      builder.addFields([
        {
          name: 'provide',
          pos: (macro null).pos,
          access: [ APublic, AStatic ],
          kind: FFun({
            params: createParams,
            ret: macro:blok.core.VNode<$nodeType>,
            args: [
              { name: 'props', type: macro:$propType },
              { name: 'build', type: macro:$providerFactory  }
            ],
            expr: macro {
              var state = new $clsTp(props);
              return blok.Provider.node({
                service: state,
                build: build,
                teardown: service -> if (service != null) service.dispose()
              });
            }
          })
        },

        {
          name: 'observe',
          pos: (macro null).pos,
          access: [ APublic, AStatic ],
          kind: FFun({
            params: createParams,
            ret: macro:blok.core.VNode<$nodeType>,
            args: [
              { name: 'context', type: macro:blok.core.Context<$nodeType> },
              { name: 'build', type: macro:$observerFactory }
            ],
            expr: macro {
              var state = from(context);
              return blok.ChangeSubscriber.node({
                target: state,
                build: build
              });
            }
          })
        },
      ]);

      return macro class {
        var $PROPS:$propType;
        var __dirty:Bool = false;
        final __signal = new blok.Signal<$ct>();
        
        public function new($INCOMING_PROPS:$propType) {
          this.$PROPS = ${ {
            expr: EObjectDecl(initializers),
            pos: (macro null).pos
          } };
          $b{initHooks};
        }

        public function getChangeSignal():blok.Signal<$ct> {
          return __signal;
        }

        public function getCurrentValue():$ct {
          return this;
        }

        @:noCompletion
        function __updateProps($INCOMING_PROPS:$updatePropsType) {
          $b{updates};
        }

        public function dispose() {
          __signal.dispose();
          $b{disposeHooks};
        }
      };
    });

    return builder.export();
  }
}
