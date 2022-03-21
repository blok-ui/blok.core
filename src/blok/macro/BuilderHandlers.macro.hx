package blok.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import blok.macro.ClassBuilder;
import blok.macro.BuilderHelpers.*;

using haxe.macro.Tools;

function createMemoFieldHandler(onInvalidate:(e:Expr)->Void):FieldMetaHandler<{}> {
  return {
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
        
        onInvalidate(macro this.$memoName = null);
      default:
        Context.error('@memo must be used on a method', field.pos);
    }
  };
}

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
          inline function $getName() return $i{PROPS}.$name;
        });

        addProp(name, t, e != null);
        addInitializer(name, init);
        
        if (onChange.length > 0 ) {
          addInitHook(macro {
            var prev = null;
            var value = __props.$name;
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
                __currentRevision++;
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
