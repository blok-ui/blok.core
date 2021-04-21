import blok.Html;
import blok.Platform;
import blok.Component;
import blok.Service;
import blok.Provider;

using Medic;
using helpers.VNodeAssert;

class TestService implements TestCase {
  public function new() {}

  @:test('Services fallback to a default value')
  public function testServiceFallback() {
    var context = Platform.createContext();
    var service = SimpleService.from(context);
    service.value.equals('default');
  }

  @:test('Services can be registered to Context')
  public function testServiceRegister() {
    var context = Platform.createContext();
    var service = new SimpleService('foo');
    service.register(context);
    SimpleService.from(context).value.equals('foo');
  }

  // Todo: the following tests should probably be pulled out
  //       into an integration test?

  @:test('services work with Provider')
  @:test.async
  public function testProviderIntegration(done) {
    Provider.node({
      service: new SimpleService('bar'),
      build: context -> Html.text(SimpleService.from(context).value)
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
    Html.fragment([
      UsesSimpleService.node({}), // Should use default
      Provider.node({
        service: new SimpleService('bar'),
        build: _ -> UsesSimpleService.node({}) // should use provided service
      }),
      UsesSimpleService.node({}), // Should use default
    ]).renders('defaultbardefault', done);
  }

  @:test('Services can provide other services')
  @:test.async
  public function testServiceProvider(done) {
    Provider.node({
      service: new HasProviders(),
      build: _ -> UsesSimpleService.node({})
    }).renders('provided', done);
  }
}

@service(fallback = new SimpleService('default'))
class SimpleService implements Service {
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

class UsesSimpleService extends Component {
  @use final service:SimpleService;

  override function render(context) {
    return Html.text(service.value);
  }
}
