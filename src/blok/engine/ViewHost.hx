package blok.engine;

@:using(ViewHost.ViewHostTools)
interface ViewHost {
	public function getView():View;
}

class ViewHostTools {
	public inline static function getParent(host:ViewHost):Maybe<View> {
		return host.getView().currentParent();
	}

	public static function findAncestor(host:ViewHost, match:(ancestor:View) -> Bool):Maybe<View> {
		return host.getView().findAncestor(match);
	}

	public inline static function findAncestorOfType<T:View>(host:ViewHost, kind:Class<T>):Maybe<T> {
		return host.getView().findAncestorOfType(kind);
	}

	public inline static function filterChildren(host:ViewHost, match, ?recursive) {
		return host.getView().filterChildren(match, recursive);
	}

	public inline static function findChild(host:ViewHost, match, ?recursive) {
		return host.getView().findChild(match, recursive);
	}

	public inline static function filterChildrenOfType<T:View>(host:ViewHost, kind:Class<T>, ?recursive) {
		return host.getView().filterChildrenOfType(kind, recursive);
	}

	public inline static function findChildOfType<T:View>(host:ViewHost, kind:Class<T>, ?recursive) {
		return host.getView().findChildOfType(kind, recursive);
	}
}
