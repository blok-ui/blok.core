package blok.data;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.step.*;

using haxe.macro.Tools;

final factory = new ClassBuilderFactory([
	new ConstantFieldBuildStep(),
	new SignalFieldBuildStep({updatable: false}),
	new ObservableFieldBuildStep({updatable: false}),
	new ComputedFieldBuildStep(),
	new ConstructorBuildStep({privateConstructor: false}),
	new JsonSerializerBuildStep({
		customParser: options -> switch options.type.toType().toComplexType() {
			case macro :blok.signal.Signal<$wrappedType>:
				// Unwrap any signals and then let the base parser take over.
				var name = options.name;
				Some(options.parser(macro this.$name.get(), name, wrappedType));
			default:
				None;
		}
	})
]);

function build() {
	return factory.fromContext().export();
}
