package blok.provide;

import blok.ui.ProxyWidget;

abstract class ProviderWidget<T> extends ProxyWidget {
  public final value:T;

  public function new(value, child, ?key) {
    super(child, key);
    this.value = value;
  }
}
