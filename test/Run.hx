import blok.*;
import blok.data.*;
import blok.html.server.*;
import blok.signal.*;

function main() {
	Runner.fromDefaults()
		.add(TextPrimitiveSuite)
		.add(ElementPrimitiveSuite)
		.add(UnescapedTextPrimitiveSuite)
		.add(ObjectSuite)
		.add(SuspenseSuite)
		.add(SignalSuite)
		.add(ProviderSuite)
		.run();
}
