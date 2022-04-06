package blok.state;

import haxe.Timer;
import impl.Node;
import medic.TestableComponent;

using Medic;
using medic.WidgetAssert;

class TestObservableResult implements TestCase {
  public function new() {}

  @:test('Observable result works')
  @:test.async
  function testBasic(done) {
    var tests = [
      (result:String) -> {
        result.equals('Loading...');
      },
      (result:String) -> {
        result.equals('Foo');
        done();
      }
    ];
    ObservableResult
      .await((resume, fail) -> {
        Timer.delay(() -> resume('Foo'), 100);
      })
      .render(result -> 
        TestableComponent.of({
          children: [ switch result {
            case Suspended:
              Node.text('Loading...');
            case Success(data):
              Node.text(data);
            case Failure(error):
              Node.text(error);
          } ],
          test: result -> {
            var test = tests.shift();
            if (test != null) test(result.getObject().toString());
          }
        })
      )
      .renderWithoutAssert();
  }
}
