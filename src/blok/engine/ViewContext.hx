package blok.engine;

@:forward
abstract ViewContext(View) from View {
	@:from public static inline function ofViewHost(host:ViewHost):ViewContext {
		return host.getView();
	}

	@:to public function unwrap():View {
		return this;
	}
}
