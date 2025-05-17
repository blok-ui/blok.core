package blok.engine;

enum ViewRenderMode {
	Normal;
	Hydrating;
}

enum ViewStatus {
	Invalid;
	Valid;
	Rendering(mode:ViewRenderMode);
	Rendered;
	Disposing;
	Disposed;
}
