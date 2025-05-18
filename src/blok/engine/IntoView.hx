package blok.engine;

@:forward
abstract IntoView(View) from View {
	@:from public static inline function ofViewHost(host:ViewHost):IntoView {
		return host.getView();
	}

	@:to public function unwrap():View {
		return this;
	}
}
