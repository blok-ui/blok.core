package blok.framework.context;

/**
  Allows the registration of many services at once.
**/
class ServiceBundle {
  final services:Array<ServiceProvider>;

  public function new(services) {
    this.services = services;
  }

  public function addService(service:ServiceProvider) {
    services.push(service);
    return this;
  }

  public inline function provide(build) {
    return Provider.provide(this, build);
  }

  public function register(context:Context) {
    for (service in services) service.register(context);
  }
}
