package blok;

typedef Changes<T> = {
  public function getCurrentValue():T;
  public function getChangeSignal():Signal<T>;
}
