import blok.data.*;
import blok.html.server.*;
import blok.suspense.*;
import blok.signal.*;

function main() {
	Runner.fromDefaults()
		.add(TextPrimitiveSuite)
		.add(ElementPrimitiveSuite)
		.add(UnescapedTextPrimitiveSuite)
		.add(ObjectSuite)
		.add(SuspenseSuite)
		.add(SignalSuite)
		.run();
}
