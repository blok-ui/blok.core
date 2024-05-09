package blok.data;

import blok.macro.*;
import haxe.macro.Expr;
import kit.macro.*;
import kit.macro.parser.*;

using haxe.macro.Tools;

final factory = new ClassBuilderFactory([
	new ConstantFieldParser(),
	new SignalFieldParser({updatable: false}),
	new ObservableFieldParser({updatable: false}),
	new ComputedFieldParser(),
	new ConstructorParser({privateConstructor: false}),
	new JsonSerializerParser({
		customParser: (name, t, parser) -> switch t.toType().toComplexType() {
			case macro :blok.signal.Signal<$wrappedType>:
				// Unwrap any signals and then let the base parser take over.
				Some(parser(macro this.$name.get(), name, wrappedType));
			default:
				None;
		}
	})
]);

function build() {
	return factory.fromContext().export();
}
