package blok.data;

import blok.macro.*;
import kit.macro.*;
import kit.macro.parser.*;

final factory = new ClassBuilderFactory([
	new ConstantFieldParser(),
	new SignalFieldParser({updatable: false}),
	new ObservableFieldParser({updatable: false}),
	new ComputedFieldParser(),
	new ConstructorParser({privateConstructor: false}),
	new JsonSerializerParser({})
]);

function build() {
	return factory.fromContext().export();
}
