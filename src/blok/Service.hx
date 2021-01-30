package blok;

import blok.core.Context;

@:autoBuild(blok.ServiceBuilder.autoBuild())
interface Service {
  public function register(context:Context<Dynamic>):Void;
}
