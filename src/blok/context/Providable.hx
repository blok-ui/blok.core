package blok.context;

import blok.core.Disposable;

interface Providable extends Disposable {
  public function getContextId():Int;
}
