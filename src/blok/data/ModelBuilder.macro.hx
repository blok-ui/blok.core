package blok.data;

import blok.macro.*;
import blok.macro.builder.*;

final builderFactory = new ClassBuilderFactory([
	new ConstantFieldBuilder(),
	new SignalFieldBuilder({updatable: false}),
	new ObservableFieldBuilder({updatable: false}),
	new ComputedFieldBuilder(),
	new ConstructorBuilder({privateConstructor: false}),
	new JsonSerializerBuilder({})
]);

function build() {
	return builderFactory.fromContext().export();
}
