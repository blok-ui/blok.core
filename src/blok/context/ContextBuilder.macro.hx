package blok.context;

import blok.macro.*;
import haxe.macro.Context;
import haxe.macro.Expr;

using blok.macro.MacroTools;
using haxe.macro.Tools;

final builderFactory = new ClassBuilderFactory([
	new ContextBuilder()
]);

function build() {
	return builderFactory.fromContext().export();
}

class ContextBuilder implements Builder {
	public final priority:BuilderPriority = Late;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		var cls = builder.getClass();
		var tp:TypePath = builder.getTypePath();
		var fallback = switch cls.meta.extract(':fallback') {
			case [fallback]:
				switch fallback.params {
					case [expr]:
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
		var createParams:Array<TypeParamDecl> = cls.params.length > 0 ? [for (p in cls.params) {name: p.name, constraints: p.extractTypeParams()}] : [];
		var ret:ComplexType = TPath({
			pack: tp.pack,
			name: tp.name,
			// @todo: ...no idea if this will work. Probably not.
			params: createParams.map(p -> TPType(TPath({name: p.name, pack: []})))
		});
		var constructors = macro class {
			@:noUsing
			public static function provide(create:() -> $ret, child:(value:$ret) -> blok.ui.Child, ?key:blok.diffing.Key):blok.ui.VNode {
				return blok.context.Provider.node({
					create: create,
					child: child
				});
			}

			@:noUsing
			public inline static function from(context:blok.ui.View):$ret {
				return @:pos(fallback.pos) return maybeFrom(context).or(() -> $fallback);
			}

			@:noUsing
			public static function maybeFrom(context:blok.ui.View):kit.Maybe<$ret> {
				return context.findAncestor(ancestor -> switch Std.downcast(ancestor, blok.context.Provider) {
					case null: false;
					case provider: provider.match(__contextId);
				}).flatMap(provider -> (cast provider : blok.context.Provider<$ret>).getContext());
			}
		}

		builder.addField(constructors
			.getField('provide')
			.unwrap()
			.applyParameters(createParams));
		builder.addField(constructors
			.getField('from')
			.unwrap()
			.applyParameters(createParams));
		builder.addField(constructors
			.getField('maybeFrom')
			.unwrap()
			.applyParameters(createParams));

		builder.add(macro class {
			@:noCompletion
			public static final __contextId = new kit.UniqueId();

			public function getContextId() {
				return __contextId;
			}
		});
	}
}
