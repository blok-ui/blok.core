package blok.context;

typedef ServiceResolver<T> = {
  public function from(context:Context):T;
}
