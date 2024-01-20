package blok.ui;

import blok.macro.*;
import blok.macro.builder.*;
import haxe.macro.Expr;

using blok.macro.MacroTools;

final builderFactory = new ClassBuilderFactory([
  new AttributeFieldBuilder(),
  new SignalFieldBuilder({ updatable: true }),
  new ObservableFieldBuilder({ updatable: true }),
  new ComputedFieldBuilder(),
  new ActionFieldBuilder(),
  new ResourceFieldBuilder(),
  new ChildrenFieldBuilder(),
  new ConstructorBuilder({
    privateConstructor: true,
    customBuilder: options -> {
      var propType = options.props;
      return (macro function (node:blok.ui.VNode) {
        __node = node;
        var props:$propType = __node.getProps();
        ${options.inits}
        var prevOwner = blok.signal.Owner.setCurrent(this);
        try ${options.lateInits} catch (e) {
          blok.signal.Owner.setCurrent(prevOwner);
          throw e;
        }
        blok.signal.Owner.setCurrent(prevOwner);
        ${switch options.previousExpr {
          case Some(expr): macro blok.signal.Observer.untrack(() -> $expr);
          case None: macro null;
        }}
      }).extractFunction();
    }
  }),
  new ComponentBuilder()
]);

function build() {
  return builderFactory.fromContext().export();  
}

class ComponentBuilder implements Builder {
  public final priority:BuilderPriority = Late;

  public function new() {}

  public function apply(builder:ClassBuilder) {
    var cls = builder.getClass();
    var createParams = cls.params.toTypeParamDecl();
    var updates = builder.getHook('update');
    var props = builder.getProps('new');
    var propType:ComplexType = TAnonymous(props);
    var markupType = TAnonymous(props.concat((macro class {
      @:optional public final key:blok.diffing.Key;
    }).fields));
    var constructors = macro class {
      @:noUsing
      public static function node(props:$propType, ?key:Null<blok.diffing.Key>):blok.ui.VNode {
        return new blok.ui.VComponent(componentType, props, $i{cls.name}.new, key);
      }
  
      @:fromMarkup
      @:noUsing
      @:noCompletion
      public inline static function __fromMarkup(props:$markupType):blok.ui.VNode {
        return node(props, props.key);
      }
    };

    switch builder.findField('setup') {
      case Some(_):
      case None: builder.add(macro class {
        function setup() {}
      });
    }
  
    builder.addField(constructors
      .getField('node')
      .unwrap()
      .applyParameters(createParams));
    builder.addField(constructors
      .getField('__fromMarkup')
      .unwrap()
      .withPos(cls.pos)
      .applyParameters(createParams));
  
    builder.add(macro class {
      public static final componentType = new kit.UniqueId();
  
      function __updateProps() {
        // blok.signal.Action.run(() -> {
          var props:$propType = __node.getProps();
          @:mergeBlock $b{updates};
        // });
      }
      
      public function canBeUpdatedByNode(node:blok.ui.VNode):Bool {
        return node.type == componentType;
      }
    });
  }
}
