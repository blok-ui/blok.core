import haxe.Timer;
import blok.ChildrenComponent;
import blok.ObservableResult;
import blok.Text;

using Medic;
using helpers.VNodeAssert;

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
        ChildrenComponent.node({
          children: [ switch result {
            case Suspended:
              Text.text('Loading...');
            case Success(data):
              Text.text(data);
            case Failure(error):
              Text.text(error);
          } ],
          ref: result -> {
            var test = tests.shift();
            if (test != null) test(result);
          }
        })
      )
      .renderWithoutAssert();
  }
}
