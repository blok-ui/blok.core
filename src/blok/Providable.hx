package blok;

import blok.Disposable;

interface Providable extends Disposable {
	public function getContextId():Int;
}
