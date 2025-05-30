package blok;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

using haxe.macro.Tools;
using blok.macro.Tools;
using kit.macro.Tools;

function build() {
	return ClassBuilder.fromContext().addBundle(new ComponentBuilder()).export();
}

typedef ComponentBuilderOptions = {
	public final ?createFromMarkupMethod:Bool;
}

class ComponentBuilder implements BuildBundle implements BuildStep {
	public final priority:Priority = Late;

	final options:ComponentBuilderOptions;

	public function new(?options:ComponentBuilderOptions) {
		this.options = options ?? {createFromMarkupMethod: true};
	}

	public function steps():Array<BuildStep> return [
		new AttributeFieldBuildStep(),
		new SignalFieldBuildStep({updatable: true}),
		new ObservableFieldBuildStep({updatable: true}),
		new ComputedFieldBuildStep(),
		new ResourceFieldBuildStep(),
		new ChildrenFieldBuildStep(),
		new EffectBuildStep(),
		new ContextFieldBuildStep(),
		new ConstructorBuildStep({
			privateConstructor: true,
			customParser: options -> {
				var propType = options.props;
				var lateInits = options.builder.hook(LateInit).getExprs();
				var late = if (lateInits.length == 0) macro null else macro {
					var prevOwner = blok.core.Owner.setCurrent(this);
					try $b{lateInits} catch (e) {
						blok.core.Owner.setCurrent(prevOwner);
						throw e;
					}
					blok.core.Owner.setCurrent(prevOwner);
				};
				return (macro function(node:blok.Component.ComponentNode<$propType>, parent:kit.Maybe<blok.engine.View>, adaptor:blok.engine.Adaptor) {
					var props = node.props;
					${options.inits};
					${late};

					__view = new blok.engine.ComposableView(
						parent,
						node,
						adaptor,
						this,
						__disposables
					);

					${
						switch options.previousExpr {
							case Some(expr): macro blok.signal.Observer.untrack(() -> $expr);
							case None: macro null;
						}
					}
				}).extractFunction();
			}
		}),
		this
	];

	public function apply(builder:ClassBuilder) {
		var cls = builder.getClass();
		var componentTypePath = builder.getTypePath();
		var componentType = builder.getType().toComplexType();
		var createParams = cls.params.toTypeParamDecl();
		var props = builder.hook(Init).getProps().concat(builder.hook(LateInit).getProps());
		var updates = builder.updateHook().getExprs();
		var propType:ComplexType = TAnonymous(props);
		var markupType = TAnonymous(props.concat((macro class {
			@:optional public final key:blok.engine.Key;
		}).fields));
		var constructors = macro class {
			@:noUsing
			public static function node(props:$propType, ?key:Null<blok.engine.Key>):blok.engine.Node {
				return new blok.Component.ComponentNode(componentType, props, (node, parent, adaptor) -> new $componentTypePath(node, parent, adaptor), key);
			}

			@:fromMarkup
			@:noUsing
			@:noCompletion
			public inline static function __fromMarkup(props:$markupType):blok.engine.Node {
				return node(props, props.key);
			}
		};

		builder.findField('update')
			.inspect(field -> field.pos.error('"update" is a reserved field for Components. Did you mean "setup"?'));

		var setup = builder.setupHook().getExprs();
		switch builder.findField('setup') {
			case Some(field):
				switch field.kind {
					case FFun(f):
						var expr = f.expr;
						f.expr = macro {
							@:mergeBlock $b{setup};
							$expr;
						}
					default:
				}
			case None:
				builder.add(macro class {
					function setup() {
						@:mergeBlock $b{setup};
					}
				});
		}

		var infos = haxe.macro.Context.getPosInfos(cls.pos);

		builder.addField(constructors
			.getField('node')
			.orThrow()
			.withPos(haxe.macro.Context.makePosition({
				min: infos.min,
				max: infos.min + 1,
				file: infos.file
			}))
			.applyParameters(createParams));

		if (options.createFromMarkupMethod) {
			builder.addField(constructors
				.getField('__fromMarkup')
				.orThrow()
				.withPos(haxe.macro.Context.makePosition({
					min: infos.min,
					max: infos.min + 1,
					file: infos.file
				}))
				.applyParameters(createParams));
		}

		builder.add(macro class {
			public static final componentType = new kit.UniqueId();

			@:noCompletion
			final __view:blok.engine.ComposableView<blok.Component.ComponentNode<$propType>, $componentType>;

			public function getView():blok.engine.View {
				return __view;
			}

			public function update(node:blok.Component.ComponentNode<$propType>) {
				var props = node.props;
				@:mergeBlock $b{updates};
			}
		});
	}
}
