package blok.context;

import blok.core.Disposable;

interface HasContextId extends Disposable {
  public function getContextId():Int;
}
