package blok.context;

import haxe.macro.Context;
import haxe.macro.Expr;
import kit.macro.*;

using haxe.macro.Tools;
using kit.macro.Tools;

function build() {
	return ClassBuilder.fromContext().addStep(new ContextBuildStep()).export();
}

class ContextBuildStep implements BuildStep {
	public final priority:Priority = Late;

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
			public static function from(view:blok.ui.View):$ret {
				return @:pos(fallback.pos) return maybeFrom(view).or(() -> {
					if (__fallbackInstances == null) {
						__fallbackInstances = [];
					}

					if (!__fallbackInstances.exists(view)) {
						var fallback:$ret = $fallback;
						__fallbackInstances.set(view, fallback);
						view.addDisposable(() -> {
							__fallbackInstances.remove(view);
							fallback.dispose();
						});
					}

					return __fallbackInstances.get(view);
				});
			}

			@:noUsing
			public static function maybeFrom(view:blok.ui.View):kit.Maybe<$ret> {
				return view.findAncestor(ancestor -> switch Std.downcast(ancestor, blok.context.Provider) {
					case null: false;
					case provider: provider.match(__contextId);
				}).flatMap(provider -> (cast provider : blok.context.Provider<$ret>).getContext());
			}
		}

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

			@:noCompletion
			static var __fallbackInstances:Null<Map<blok.ui.View, Any>> = null;

			public function getContextId() {
				return __contextId;
			}
		});
	}
}
