package blok.engine;

enum ViewRenderMode {
	Normal;
	Hydrating;
}

@:using(ViewStatus.ViewStatusTools)
enum ViewStatus {
	Invalid;
	Valid;
	Rendering(mode:ViewRenderMode);
	Disposing;
	Disposed;
}

class ViewStatusTools {
	public static function isMounted(status:ViewStatus) {
		return switch status {
			case Disposing | Disposed: false;
			default: true;
		}
	}

	public static function isHydrating(status:ViewStatus) {
		return switch status {
			case Rendering(Hydrating): true;
			default: false;
		}
	}

	public static function isRendering(status:ViewStatus) {
		return switch status {
			case Rendering(_): true;
			default: false;
		}
	}
}
