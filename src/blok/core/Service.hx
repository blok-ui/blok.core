package blok.core;

@:autoBuild(blok.core.ServiceBuilder.autoBuild())
interface Service {
  public function register(context:Context<Dynamic>):Void;
}
