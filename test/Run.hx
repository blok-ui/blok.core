import blok.context.*;
import blok.data.*;
import blok.mixin.*;
import blok.html.server.*;
import blok.signal.*;
import blok.suspense.*;

function main() {
	Runner.fromDefaults()
		.add(TextPrimitiveSuite)
		.add(ElementPrimitiveSuite)
		.add(UnescapedTextPrimitiveSuite)
		.add(ObjectSuite)
		.add(SuspenseSuite)
		.add(SignalSuite)
		.add(ProviderSuite)
		.add(MixinSuite)
		.run();
}
