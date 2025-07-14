import blok.*;
import blok.data.*;
import blok.html.*;
import blok.html.server.*;
import blok.signal.*;

function main() {
	Runner.fromDefaults()
		.add(ComponentSuite)
		.add(TextPrimitiveSuite)
		.add(ElementPrimitiveSuite)
		.add(UnescapedTextPrimitiveSuite)
		.add(ObjectSuite)
		.add(ModelSuite)
		.add(SignalSuite)
		.add(ProviderSuite)
		.add(HtmlSuite)
		.add(PortalSuite)
		.add(SuspenseSuite)
		.run();
}
