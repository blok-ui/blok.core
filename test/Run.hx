import blok.*;
import blok.html.server.*;

// Yeah we're really just getting started here.
function main() {
	Runner.fromDefaults()
		.add(SignalSuite)
		.add(TextPrimitiveSuite)
		.add(ElementPrimitiveSuite)
		.run();
}
