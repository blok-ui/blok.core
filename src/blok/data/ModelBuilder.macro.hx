package blok.data;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

using haxe.macro.Tools;

function buildWithoutJsonSerializer() {
	return ClassBuilder.fromContext().addBundle(new ModelBuilder()).export();
}

function buildWithJsonSerializer() {
	return ClassBuilder.fromContext()
		.addBundle(new ModelBuilder())
		.addStep(new JsonSerializerBuildStep({
			customParser: options -> switch options.type.toType().toComplexType() {
				case macro :blok.signal.Signal<$wrappedType>:
					// Unwrap any signals and then let the base parser take over.
					var name = options.name;
					Some(options.parser(macro this.$name.get(), name, wrappedType));
				default:
					None;
			}
		}))
		.export();
}

class ModelBuilder implements BuildBundle {
	public function new() {}

	public function steps():Array<BuildStep> return [
		new AutoFieldBuildStep(),
		new SignalFieldBuildStep({updatable: false}),
		new ObservableFieldBuildStep({updatable: false}),
		new ComputedFieldBuildStep(),
		new ConstructorBuildStep({privateConstructor: false})
	];
}
