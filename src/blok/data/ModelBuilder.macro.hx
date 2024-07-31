package blok.data;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

using haxe.macro.Tools;

function build() {
	return ClassBuilder.fromContext()
		.step(new ConstantFieldBuildStep())
		.step(new SignalFieldBuildStep({updatable: false}))
		.step(new ObservableFieldBuildStep({updatable: false}))
		.step(new ComputedFieldBuildStep())
		.step(new ConstructorBuildStep({privateConstructor: false}))
		.step(new JsonSerializerBuildStep({
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
