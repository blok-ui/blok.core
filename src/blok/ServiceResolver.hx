package blok;

typedef ServiceResolver<T:ServiceProvider> = {
  public function from(context:Context):T;
}
