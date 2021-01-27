package blok.core;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.core.BuilderHelpers.*;

using Lambda;
using haxe.macro.Tools;

class ComponentBuilder {
  public static function build(e) {
    return doBuild(extractBuildCt(e));
  }

  public static function autoBuild(e) {
    return doAutoBuild(extractBuildCt(e));
  }

  static function doAutoBuild(nodeType:ComplexType):Array<Field> {
    var builder = ClassBuilder.fromContext();
    var clsTp = builder.getTypePath();
    var clsType = Context.getLocalType().toComplexType();
    var props:Array<Field> = [];
    var updateProps:Array<Field> = [];
    var updates:Array<Expr> = [];
    var initializers:Array<ObjectField> = [];
    var initHooks:Array<Expr> = [];
    var disposeHooks:Array<Expr> = [];
    var effectHooks:Array<Expr> = [];
    
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

    // Todo: this is probably too simple to work well
    builder.addClassMetaHandler({
      name: 'lazy',
      hook: After,
      options: [],
      build: function (options:{}, builder, fields) {
        if (fields.exists(f -> f.name == 'componentIsInvalid')) {
          Context.error(
            'Cannot use @lazy and a custom componentIsInvalid method',
            fields.find(f -> f.name == 'componentIsInvalid').pos
          );
        }

        var propType = TAnonymous(props);
        var checks:Array<Expr> = [ for (prop in updateProps) {
          var name = prop.name;
          macro if ($i{PROPS}.$name != previousProps.$name) return true;
        } ];

        // will this work???:
        builder.add(macro class {
          var __previousProps:$propType;
          
          override function componentIsInvalid():Bool {
            var previousProps = __previousProps;
            __previousProps = $i{PROPS};
            $b{checks};
            return false;
          }
        });
      } 
    });
    
    builder.addFieldMetaHandler({
      name: 'prop',
      hook: Normal,
      options: [],
      build: function (_, builder, f) switch f.kind {
        case FVar(t, e):
          if (t == null) {
            Context.error('Types cannot be inferred for @prop vars', f.pos);
          }

          var name = f.name;
          var getName = 'get_${name}';
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

          updates.push(macro {
            // todo: come up with something more efficient 
            if ($i{INCOMING_PROPS}.$name != null) {
              switch [
                $i{PROPS}.$name, 
                $i{INCOMING_PROPS}.$name 
              ] {
                case [ a, b ] if (a == b):
                  // noop
                case [ current, value ]:
                  $i{PROPS}.$name = value;
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

          if (!Context.unify(t.toType(), Context.getType('blok.core.Service'))) {
            Context.error('@use must be a blok.core.Service', field.pos);
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
              if (this.$backingName == null) 
                this.$backingName = $p{path}.from(__context);
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
      build: function (options:{ ?silent:Bool }, builder, field) switch field.kind {
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
                invalidateComponent();
              case UpdateState(data): 
                __updateProps(data);
                invalidateComponent();
              case UpdateStateSilent(data):
                __updateProps(data);
            }
          }
        default:
          Context.error('@update must be used on a method', field.pos);
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
      name: 'effect',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(func):
          if (func.args.length > 0) {
            Context.error('@effect methods cannot have any arguments', field.pos);
          }
          var name = field.name;
          effectHooks.push(macro this.$name);
        default:
          Context.error('@effect must be used on a method', field.pos);
      }
    });

    builder.addLater(() -> {
      var propType = TAnonymous(props);
      var updateType = TAnonymous(updateProps);
      var createParams = builder.cls.params.length > 0
        ? [ for (p in builder.cls.params) { name: p.name, constraints: BuilderHelpers.extractTypeParams(p) } ]
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
              { name: 'key', type: macro:Null<blok.core.Key>, opt: true }
            ],
            expr: macro return VComponent(__type, props, key),
            ret: macro:blok.core.VNode<$nodeType>
          })
        }
      ]);

      return macro class {
        @:noCompletion
        static final __type = {
          create: (props, parent, context) -> new $clsTp(props, parent, context),
          update: (component, props, parent, context) -> {
            var comp:$clsType = cast component;
            comp.__doUpdate(cast props, parent, context);
            return comp;
          }
        }

        // public static function node(props, ?key):blok.core.VNode<$nodeType> {
        //   return VComponent(__type, props, key);
        // }

        var $PROPS:$propType;

        public function new($INCOMING_PROPS:$propType, __parent, __context) {
          this.$PROPS = ${ {
            expr: EObjectDecl(initializers),
            pos: (macro null).pos
          } };
          __setParent(__parent);
          __setContext(__context);
          $b{initHooks}
          executeRender(false);
        }

        @:noCompletion
        function __doUpdate(props, parent, context) {
          __updateProps(props);
          __setContext(context);
          __setParent(parent);
          if (componentIsInvalid()) {
            executeRender(false);
          }
        }

        @:noCompletion
        function __updateProps($INCOMING_PROPS:$updateType) {
          $b{updates};
        }

        override function getSideEffects() {
          return [ $a{ effectHooks } ];
        }

        override function dispose() {
          $b{disposeHooks};
          super.dispose();
        }
      }
    });
    
    return builder.export();
  }

  static function doBuild(nodeType:ComplexType):Array<Field> {
    var builder = ClassBuilder.fromContext();
    var clsTp = builder.getTypePath();
    var clsType = Context.getLocalType().toComplexType();

    builder.add(macro class {
      @:noCompletion public var __alive:Bool = true;
      @:noCompletion public var __invalid:Bool = false;
      @:noCompletion var __context:blok.core.Context<$nodeType>;
      @:noCompletion var __parent:blok.core.Component<$nodeType>;
      @:noCompletion var __rendered:blok.core.RenderResult<$nodeType>;
      @:noCompletion var __pendingChildren:Array<blok.core.Component<$nodeType>> = [];
      @:noCompletion var __previousContext:blok.core.Context<$nodeType>;

      @:noCompletion
      public function __setContext(context:blok.core.Context<$nodeType>) {
        __context = context;
      }

      @:noCompletion
      public function __setParent(parent:blok.core.Component<$nodeType>) {
        __parent = parent;
      }

      @:noCompletion
      function executeRender(asRoot:Bool = false) {
        __preRender();
        switch __rendered {
          case null:
            blok.core.Differ.renderAll(
              __processRender(),
              this,
              __context,
              result -> {
                __rendered = result;
                if (asRoot) __rendered.dispatchEffects();
              }
            );
          case before:
            var previousCount = 0;
            var first:$nodeType = null;

            blok.core.Differ.updateAll(
              before,
              __processRender(),
              this,
              __context,
              result -> {
                __rendered = result;
            
                for (node in before.getNodes()) {
                  if (first == null) first = node;
                  previousCount++;
                }

                blok.core.Differ.setChildren(
                  previousCount,
                  __context.engine.traverseSiblings(first),
                  __rendered
                );

                if (asRoot) __rendered.dispatchEffects();
              }
            );
        }
      }

      @:noCompletion
      function __preRender() {
        if (!__alive) {
          #if debug
          throw 'Attempted to render a component that is not mounted or was disposed';
          #end
        }
        __invalid = false;
        __pendingChildren = [];
      }

      @:noCompletion
      public function __processRender():Array<blok.core.VNode<$nodeType>> {
        return switch render(__context) {
          case null | VFragment([], _): [ __context.engine.createPlaceholder(this) ];
          case VFragment(children, _): children;
          case node: [node];
        }
      }

      public function getSideEffects():Array<()->Void> {
        return [];
      }

      public function getLastRenderResult():blok.core.RenderResult<$nodeType> {
        return __rendered;
      }

      public function invalidateComponent() {
        if (__invalid) return;

        __invalid = true;

        if (__parent == null) {
          __context.scheduler.schedule(executeRender.bind(true));
        } else {
          __parent.enqueuePendingChild(this);
        }
      }

      public function componentIsInvalid():Bool {
        return true;
      }

      public function componentIsAlive():Bool {
        return __alive;
      }

      public function render(context:blok.core.Context<$nodeType>):blok.core.VNode<$nodeType> {
        return null;
      }

      public function dispose() {
        if (__rendered != null) __rendered.dispose();
        __alive = false;
        __parent = null;
        __pendingChildren = [];
        __context = null;
        __rendered = null;
      }
      
      @:noCompletion
      function enqueuePendingChild(child) {
        if (__invalid || __pendingChildren.contains(child)) return;
        
        __pendingChildren.push(child);

        if (__parent == null) {
          __context.scheduler.schedule(dequeuePendingChildren);
        } else {
          __parent.enqueuePendingChild(this);
        }
      }

      @:noCompletion
      function dequeuePendingChildren() {
        if (__pendingChildren.length == 0) return;

        var children = __pendingChildren.copy();

        __pendingChildren = [];

        for (child in children) {
          if (child.componentIsAlive()) {
            if (child.componentIsInvalid()) {
              child.executeRender(true);
            } else {
              child.dequeuePendingChildren();
            }
          }
        }
      }
    });

    return builder.export();
  }

  static function extractBuildCt(e:Expr):ComplexType {
    return switch e {
      case macro ($_:$ct): ct;
      default:
        Context.error('Expected a complex type', e.pos);
        null;
    }
  }
}
