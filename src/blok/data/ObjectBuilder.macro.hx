package blok.data;

import blok.macro.*;
import kit.macro.*;
import kit.macro.step.*;

function build() {
	return ClassBuilder.fromContext().addBundle(new ObjectBuilder()).export();
}

class ObjectBuilder implements BuildBundle {
	public function new() {}

	public function steps():Array<BuildStep> return [
		new AutoFieldBuildStep(),
		new PropertyBuildStep(),
		new ConstructorBuildStep({privateConstructor: false})
	];
}
