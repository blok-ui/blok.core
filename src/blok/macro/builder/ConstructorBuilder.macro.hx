package blok.macro.builder;

import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;
using blok.macro.MacroTools;

typedef ConstructorBuilderOptions = {
  public final ?customBuilder:(options:{
    builder:ClassBuilder,
    props:ComplexType,
    previousExpr:Maybe<Expr>,
    inits:Expr,
    lateInits:Expr
  })->Function;
} 

class ConstructorBuilder implements Builder {
	public final priority:BuilderPriority = Late;

  final options:ConstructorBuilderOptions;

  public function new(options) {
    this.options = options;
  }

  public function apply(builder:ClassBuilder) {
    var props = builder.getProps('new');
    var init = builder.getHook('init');
    var late = builder.getHook('init:late');
    var propsType:ComplexType = TAnonymous(props);
    var currentConstructor = builder.findField('new'); 
    var previousConstructorExpr:Maybe<Expr> = switch currentConstructor {
      case Some(field): switch field.kind {
        case FFun(f):
          if (f.args.length > 0) {
            Context.error(
              'You cannot pass arguments to this constructor -- it can only '
              + 'be used to run code at initialization.',
              field.pos
            );
          }
          
          if (field.access.contains(APublic)) {
            Context.error(
              'Component constructors must be private (remove the `public` keyword)',
              field.pos
            );
          }
  
          Some(f.expr);
        default: 
          throw 'assert';
      }
      case None:
        None;
    }
    var func:Function = switch options.customBuilder {
      case null if (Context.unify(builder.getType(), (macro:blok.core.Disposable).toType())):
        (macro function (props:$propsType) {
          @:mergeBlock $b{init};
          var prevOwner = blok.signal.Graph.setCurrentOwner(Some(this));
          try $b{late} catch (e) {
            blok.signal.Graph.setCurrentOwner(prevOwner);
            throw e;
          }
          blok.signal.Graph.setCurrentOwner(prevOwner);
          ${switch previousConstructorExpr {
            case Some(expr): macro blok.signal.Observer.untrack(() -> $expr);
            case None: macro null;
          }}
        }).extractFunction();
      case null:
        (macro function (props:$propsType) {
          @:mergeBlock $b{init};
          @:mergeBlock $b{late};
          ${switch previousConstructorExpr {
            case Some(expr): expr;
            case None: macro null;
          }}
        }).extractFunction();
      case custom:
        custom({ 
          builder: builder,
          props: propsType,
          previousExpr: previousConstructorExpr,
          inits: macro @:mergeBlock $b{init},
          lateInits: macro @:mergeBlock $b{late},
        });
    }

    switch currentConstructor {
      case Some(field):
        field.kind = FFun(func);
      case None:
        builder.addField({
          name: 'new',
          access: [ APublic ],
          kind: FFun(func),
          pos: (macro null).pos
        });
    }
  }
}
