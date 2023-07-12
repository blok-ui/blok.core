package blok.ui;

import blok.diffing.Key;

interface VNode {
  public final type:UniqueId;
  public final key:Null<Key>;
  public function getProps<T:{}>():T;
  public function createComponent():ComponentBase;
}
