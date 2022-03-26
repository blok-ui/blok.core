package blok.context;

import blok.ui.Component;
import impl.Node;

using Medic;
using medic.WidgetAssert;

class TestService implements TestCase {
  public function new() {}

  @:test('Services fallback to a default value')
  public function testServiceFallback() {
    var context = new Context();
    var service = SimpleService.from(context);
    service.value.equals('default');
  }

  @:test('Services can be registered to Context')
  public function testServiceRegister() {
    var context = new Context();
    var service = new SimpleService('foo');
    service.register(context);
    SimpleService.from(context).value.equals('foo');
  }

  @:test('Services are available inside context scopes')
  @:test.async
  public function testScope(done) {
    Provider.node({
      service: new SimpleService('bar'),
      build: _ -> Context.use(context -> Node.text(SimpleService.from(context).value)) 
    }).renders('bar', done);
  }

  @:test('The `use` static function will get the service from the closest context')
  @:test.async
  public function testUse(done) {
    Provider.node({
      service: new SimpleService('bar'),
      build: _ -> SimpleService.use(service -> Node.text(service.value)) 
    }).renders('bar', done);
  }

  // Todo: the following tests should probably be pulled out
  //       into an integration test?

  @:test('services work with Provider')
  @:test.async
  public function testProviderIntegration(done) {
    Provider.node({
      service: new SimpleService('bar'),
      build: context -> Node.text(SimpleService.from(context).value)
    }).renders('bar', done);
  }

  @:test('Services work with @use')
  @:test.async
  public function testComponentIntegration(done) {
    Provider.node({
      service: new SimpleService('bar'),
      build: _ -> UsesSimpleService.node({})
    }).renders('bar', done);
  }

  @:test('Provider scopes services')
  @:test.async
  public function testComponentIntegrationScope(done) {
    Node.fragment(
      UsesSimpleService.node({}), // Should use default
      Provider.node({
        service: new SimpleService('bar'),
        build: _ -> UsesSimpleService.node({}) // should use provided service
      }),
      UsesSimpleService.node({}) // Should use default
    ).renders('default bar default', done);
  }

  @:test('Services can provide other services')
  @:test.async
  public function testServiceProvider(done) {
    Provider.node({
      service: new HasProviders(),
      build: _ -> SimpleService.use(service -> Node.text(service.value))
    }).renders('provided', done);
  }

  @:test('Services can use other services')
  @:test.async
  public function testServicesCanUseServices(done) {
    Provider
      .factory()
      .provide(new SimpleService('foo'))
      .provide(new ServiceUsesService())
      .render(context -> Node.text(ServiceUsesService
        .from(context)
        .getSimpleService()
        .value
      ))
      
      .renders('foo', done);
  }

  @:test('services work with nested Providers')
  @:test.async
  public function testNestedProviderIntegration(done) {
    Node.fragment(
      UsesSimpleService.node({}), // Should use default
      Provider.node({
        service: new SimpleService('simple'),
        build: _ -> Node.fragment(
          UsesSimpleService.node({}), // should use provided service
          Provider.node({
            service: new OtherService('other'),
            build: context -> Node.text(
              SimpleService.from(context).value + ' ' // Should be from outer scope
              + OtherService.from(context).value
            )
          })
        )
      })
    ).renders('default simple simple other', done);
  }

  @:test('Services can be optional')
  @:test.async
  function testServicesCanBeOptional(done) {
    Provider.provide(new SimpleService('foo'), context -> {
      var optional = OptionalService.from(context);
      Node.text(optional == null ? 'none' : optional.foo);
    }).renders('none', done);
  }

  @:test('Services can use Context directly')
  function testServicesCanUseContext() {
    var context = new Context();
    var service = UsesContext.from(context.getChild());

    context.set('foo', 'foo');

    (service.getContext().get('foo'):String).equals('foo');
  }
}

@service(fallback = new SimpleService('default'))
class SimpleService implements Service {
  public final value:String;

  public function new(value) {
    this.value = value;
  }
}

@service(fallback = new OtherService('default'))
class OtherService implements Service {
  public final value:String;

  public function new(value) {
    this.value = value;
  }
}

@service(fallback = new HasProviders())
class HasProviders implements Service {
  @provide public final simple:SimpleService = new SimpleService('provided');

  public function new() {}
}

@service(fallback = new ServiceUsesService())
class ServiceUsesService implements Service {
  @use var service:SimpleService;

  public function new() {}

  public function getSimpleService() {
    return service;
  }
}

@service(isOptional)
class OptionalService implements Service {
  @use var service:SimpleService;
  @prop public var foo:String;
}

class UsesSimpleService extends Component {
  @use final service:SimpleService;

  public function render() {
    return Node.text(service.value);
  }
}

@service(fallback = new UsesContext())
class UsesContext implements Service {
  @use var context:Context;

  public function new() {}

  public function getContext() {
    return context;
  }
}
