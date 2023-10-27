package blok.data;

import blok.macro.build.*;
import blok.macro.build.field.*;
import blok.macro.build.finalizer.*;

final builderFactory = new ClassBuilderFactory([
  new ConstantFieldBuilder(),
  new SignalFieldBuilder({ updatable: false }),
  new ObservableFieldBuilder({ updatable: false }),
  new ComputedFieldBuilder(),
  new ActionFieldBuilder(),
  new ConstructorBuilder({}),
  new JsonSerializerBuilder({})
]);

function build() {
  return builderFactory.fromContext().export();
}
