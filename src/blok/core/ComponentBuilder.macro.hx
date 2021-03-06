package blok.core;

import haxe.macro.Context;
import haxe.macro.Expr;
import blok.core.BuilderHelpers.*;

using Lambda;
using haxe.macro.Tools;

class ComponentBuilder {
  public static function build(e) {
    return doBuild(extractComplexTypeFromExpr(e));
  }

  public static function autoBuild(e) {
    return doAutoBuild(extractComplexTypeFromExpr(e));
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

    builder.addClassMetaHandler({
      name: 'lazy',
      hook: After,
      options: [],
      build: function (options:{}, builder, fields) {
        if (fields.exists(f -> f.name == 'componentShouldUpdate')) {
          Context.error(
            'Cannot use @lazy and a custom componentShouldUpdate method',
            fields.find(f -> f.name == 'componentShouldUpdate').pos
          );
        }
        builder.add(macro class {
          override function componentShouldUpdate():Bool {
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

          updates.push(macro {
            if (Reflect.hasField($i{INCOMING_PROPS}, $v{name})) {
              switch [
                $i{PROPS}.$name, 
                $i{INCOMING_PROPS}.$name 
              ] {
                case [ a, b ] if (!${comparator}):
                  // noop
                case [ current, value ]:
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
              throw 'Cannot update a component that is rendering';
            }
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
      name: 'memo',
      hook: After,
      options: [],
      build: function (_, builder, field) switch field.kind {
        case FFun(f):
          var name = field.name;
          var memoName = '__memo_$name';

          if (f.ret != null && Context.unify(f.ret.toType(), Context.getType('Void'))) {
            Context.error('@memo functions cannot have a Void return type', field.pos);
          }
          if (f.args.length > 0) {
            Context.error('@memo functions cannot have arguments', field.pos);
          }

          builder.add(macro class {
            var $memoName = null;
          });

          f.expr = macro {
            if (this.$memoName != null) return this.$memoName;
            this.$memoName = ${f.expr};
            return this.$memoName;
          };
          
          updates.push(macro this.$memoName = null);
        default:
          Context.error('@memo must be used on a method', field.pos);
      }
    });

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

        @:noCompletion var $PROPS:$propType;
        @:noCompletion var __hasSideEffects:Bool = true;

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
          if (componentShouldUpdate()) {
            __hasSideEffects = true;
            executeRender(false);
          } else {
            __hasSideEffects = false;
          }
        }

        @:noCompletion
        function __updateProps($INCOMING_PROPS:$updateType) {
          __lastRevision = __currentRevision;
          $b{updates};
        }

        override function getSideEffects() {
          return if (__hasSideEffects) [ $a{ effectHooks } ] else [];
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
      @:noCompletion var __alive:Bool = true;
      @:noCompletion var __invalid:Bool = false;
      @:noCompletion var __isRendering:Bool = false;
      @:noCompletion var __lastRevision:Int = -1;
      @:noCompletion var __currentRevision:Int = 0;
      @:noCompletion var __context:blok.core.Context<$nodeType>;
      @:noCompletion var __parent:blok.core.Component<$nodeType>;
      @:noCompletion var __renderResult:blok.core.RenderResult<$nodeType>;
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
        __isRendering = true;
        __preRender();
        switch __renderResult {
          case null:
            blok.core.Differ.renderAll(
              __processRender(),
              this,
              __context,
              result -> {
                __renderResult = result;
                if (asRoot) inline __dispatchRootEffects();
                __isRendering = false;
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
                __renderResult = result;
            
                for (node in before.getNodes()) {
                  if (first == null) first = node;
                  previousCount++;
                }

                blok.core.Differ.setChildren(
                  previousCount,
                  __context.engine.traverseSiblings(first),
                  __renderResult
                );

                if (asRoot) inline __dispatchRootEffects();
                __isRendering = false;
              }
            );
        }
      }

      // @todo: I feel like the way side-effects works is a bit messy.
      //        Keep thinking out it.
      @:noCompletion
      function __dispatchRootEffects() {
        __renderResult.dispatchEffects();
        for (e in getSideEffects()) e();
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

      public function getRenderResult():blok.core.RenderResult<$nodeType> {
        return __renderResult;
      }

      public function invalidateComponent() {
        if (__invalid) return;

        __invalid = true;

        if (__parent == null) {
          __context.scheduler.schedule(() -> executeRender(true));
        } else {
          __parent.enqueuePendingChild(this);
        }
      }

      public function componentIsInvalid():Bool {
        return __invalid;
      }

      public function componentShouldUpdate() {
        return true;
      }

      public function componentIsAlive():Bool {
        return __alive;
      }

      public function render(context:blok.core.Context<$nodeType>):blok.core.VNode<$nodeType> {
        return null;
      }

      public function dispose() {
        if (__renderResult != null) __renderResult.dispose();
        __alive = false;
        __parent = null;
        __pendingChildren = [];
        __context = null;
        __renderResult = null;
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
}
