package blok.context;

import blok.macro.ClassBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;

using blok.macro.MacroTools;
using haxe.macro.Tools;

function build() {
  var builder = ClassBuilder.fromContext();
  var cls = Context.getLocalClass().get();
  var tp:TypePath = { pack: cls.pack, name: cls.name };
  var fallback = switch cls.meta.extract(':fallback') {
    case [ fallback ]: switch fallback.params {
      case [ expr ]:
        expr;
      case []:
        Context.error('Expression required', fallback.pos);
      default:
        Context.error('Too many params', fallback.pos);
    }
    case []:
      Context.error('Context classes require :fallback meta', cls.pos);
    default:
      Context.error('Only one :fallback meta is allowed', cls.pos);
  }
  var createParams:Array<TypeParamDecl> = cls.params.length > 0
    ? [ for (p in cls.params) { name: p.name, constraints: p.extractTypeParams() } ]
    : [];
  var ret:ComplexType = TPath({
    pack: tp.pack,
    name: tp.name,
    // @todo: ...no idea if this will work. Probably not.
    params: createParams.map(p -> TPType(TPath({ name: p.name, pack: [] })))
  });

  builder.addField({
    name: 'provide',
    access: [ APublic, AStatic ],
    meta: [],
    kind: FFun({
      params: createParams,
      ret: macro:blok.ui.VNode,
      args: [
        { name: 'create', type: macro:()->$ret  },
        { name: 'child', type: macro:(value:$ret)->blok.ui.Child },
        { name: 'key', type: macro:Null<blok.diffing.Key>, opt: true }
      ],
      expr: macro return blok.context.Provider.node({
        create: create,
        child: child
      })
    }),
    pos: (macro null).pos
  });

  builder.addField({
    name: 'from',
    access: [ APublic, AStatic ],
    meta: [],
    kind: FFun({
      params: createParams,
      ret: ret,
      args: [
        { name: 'context', type: macro:Component }
      ],
      expr: macro @:pos(fallback.pos) return context.findAncestor(ancestor -> switch Std.downcast(ancestor, blok.context.Provider) {
        case null: false;
        case provider: provider.match(__contextId);
      }).flatMap(provider -> (cast provider:blok.context.Provider<$ret>).getContext())
        .or(() -> $fallback)
    }),
    pos: (macro null).pos
  });

  builder.add(macro class {
    @:noCompletion
    public static final __contextId = new kit.UniqueId();

    public function __getContextId() {
      return __contextId;
    }
  });

  return builder.export();
}
