package blok.ui;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

using kit.macro.Tools;

final factory = new ClassBuilderFactory([
	new AttributeFieldBuildStep(),
	new SignalFieldBuildStep({updatable: true}),
	new ObservableFieldBuildStep({updatable: true}),
	new ComputedFieldBuildStep(),
	new ResourceFieldBuildStep(),
	new ChildrenFieldBuildStep(),
	new EffectBuildStep(),
	new ConstructorBuildStep({
		privateConstructor: true,
		customParser: options -> {
			var propType = options.props;
			return (macro function(node:blok.ui.VNode) {
				__node = node;
				var props:$propType = __node.getProps();
				${options.inits};
				var prevOwner = blok.core.Owner.setCurrent(this);
				try ${options.lateInits} catch (e) {
					blok.core.Owner.setCurrent(prevOwner);
					throw e;
				}
				blok.core.Owner.setCurrent(prevOwner);
				${
					switch options.previousExpr {
						case Some(expr): macro blok.signal.Observer.untrack(() -> $expr);
						case None: macro null;
					}
				}
			}).extractFunction();
		}
	}),
	new ComponentBuilder()
]);

function build() {
	return factory.fromContext().export();
}

class ComponentBuilder implements BuildStep {
	public final priority:Priority = Late;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		var cls = builder.getClass();
		var createParams = cls.params.toTypeParamDecl();
		var updates = builder.hook('update').getExprs();
		var props = builder.hook(Init).getProps().concat(builder.hook(LateInit).getProps());
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

		var setup = builder.hook('setup').getExprs();
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
				var props:$propType = __node.getProps();
				@:mergeBlock $b{updates};
			}

			public function canBeUpdatedByNode(node:blok.ui.VNode):Bool {
				return node.type == componentType;
			}
		});
	}
}
