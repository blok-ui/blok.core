package blok;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

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
				return (macro function(node:blok.VNode) {
					__node = node;
					var props:$propType = __node.getProps();
					${options.inits};
					var prevOwner = blok.Owner.setCurrent(this);
					try ${options.lateInits} catch (e) {
						blok.Owner.setCurrent(prevOwner);
						throw e;
					}
					blok.Owner.setCurrent(prevOwner);
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
		var createParams = cls.params.toTypeParamDecl();
		var updates = builder.updateHook().getExprs();
		var props = builder.hook(Init).getProps().concat(builder.hook(LateInit).getProps());
		var propType:ComplexType = TAnonymous(props);
		var markupType = TAnonymous(props.concat((macro class {
			@:optional public final key:blok.Key;
		}).fields));
		var constructors = macro class {
			@:noUsing
			public static function node(props:$propType, ?key:Null<blok.Key>):blok.VNode {
				return new blok.VComposableView(componentType, props, $i{cls.name}.new, key);
			}

			@:fromMarkup
			@:noUsing
			@:noCompletion
			public inline static function __fromMarkup(props:$markupType):blok.VNode {
				return node(props, props.key);
			}
		};

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
			.unwrap()
			.withPos(haxe.macro.Context.makePosition({
				min: infos.min,
				max: infos.min + 1,
				file: infos.file
			}))
			.applyParameters(createParams));

		if (options.createFromMarkupMethod) {
			builder.addField(constructors
				.getField('__fromMarkup')
				.unwrap()
					// Not sure about this positioning thing...
				.withPos(haxe.macro.Context.makePosition({
					min: infos.min,
					max: infos.min + 1,
					file: infos.file
				}))
				.applyParameters(createParams));
		}

		builder.add(macro class {
			public static final componentType = new kit.UniqueId();

			function __updateProps() {
				var props:$propType = __node.getProps();
				@:mergeBlock $b{updates};
			}

			public function canBeUpdatedByNode(node:blok.VNode):Bool {
				return node.type == componentType;
			}
		});
	}
}
