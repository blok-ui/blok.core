package blok.test;

import blok.engine.*;

class Sandbox<Primitive> {
	final adaptor:Adaptor;
	final createContainer:() -> Primitive;

	public function new(adaptor, createContainer) {
		this.adaptor = adaptor;
		this.createContainer = createContainer;
	}

	public function wrap(body:Child):SandboxView<Primitive> {
		return new SandboxView(createContainer(), adaptor, body);
	}

	public function render(body:Child):Task<Root<Primitive>> {
		return wrap(body).mount();
	}
}
