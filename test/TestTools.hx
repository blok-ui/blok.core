import blok.Child;
import blok.html.server.*;
import blok.test.*;

final sandbox = new SandboxFactory(new ServerAdaptor(), () -> new ElementPrimitive('#document'));

function renderAsync(node:Child) {
	return sandbox.render(node);
}

function createSandbox(node:Child) {
	return sandbox.wrap(node);
}
