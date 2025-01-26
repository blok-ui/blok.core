package blok.data;

import blok.macro.*;
import kit.macro.*;
import kit.macro.step.*;

function build() {
	return ClassBuilder.fromContext().addBundle(new ObjectBuilder()).export();
}

function buildWithJsonSerializer() {
	return ClassBuilder.fromContext()
		.addBundle(new ObjectBuilder())
		.addStep(new JsonSerializerBuildStep({}))
		.export();
}

class ObjectBuilder implements BuildBundle {
	public function new() {}

	public function steps():Array<BuildStep> return [
		new ValueFieldBuildStep(),
		new PropertyBuildStep(),
		new ConstructorBuildStep({privateConstructor: false})
	];
}
