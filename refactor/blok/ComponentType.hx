package blok;

typedef ComponentType<T:Component, Props:{}> = {
  public function create(props:Props):T;
  public function update(component:T, props:Props):Void;
}
