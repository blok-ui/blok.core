import blok.Effect;
import blok.SuspendableData;
import blok.ChildrenComponent;
import blok.Suspend;
import blok.Component;
import blok.Text;

using Medic;
using helpers.VNodeAssert;

class TestSuspend implements TestCase {
  public function new() {}

  @:test('Components can be suspended')
  @:test.async
  public function testSimple(done) {
    var ready = false;
    var makeReady = () -> ready = true;
    
    Suspend.await(
      () -> Suspendable.node({
        ready: ready,
        makeReady: makeReady,
        test: comp -> {
          comp.ref.equals('done');
          done();
        }
      }),
      () -> Text.text('waiting')
    ).renderWithoutAssert();
  }

  @:test('Suspensions can be tracked')
  @:test.async
  public function testTracking(done) {
    var ready:Bool = false;
    var ref:ChildrenComponent = null;
    Suspend.isolate(context -> {
      Suspend
        .from(context)
        .status.observeNext(status -> switch status {
          case Complete:
            ref.toString().equals('foo bar');
            done();
          case Suspended:
        });

      Suspend.await(
        () -> ChildrenComponent.node({ 
          get: self -> ref = self,
          children: [
            Text.text('foo'),
            Suspend.await(
              () -> if (ready) {
                Text.text('bar');
              } else 
                Suspend.suspend(resume -> {
                  ready = true;
                  resume();
                }),
              () -> Text.text('inner')
            ),
          ]
        }),
        () -> Text.text('nah')
      );
    }).renderWithoutAssert();
  }

  @:test('Suspensions work with SuspendableData')
  @:test.async
  public function testSuspendableData(done) {
    var data:SuspendableData<String> = SuspendableData.suspended();
    Suspend.await(
      () -> Effect.withEffect(
        Text.text(data.get()), 
        () -> {
          data.get().equals('foo');
          done();
        }
      ),
      () -> Effect.withEffect(
        Text.text('waiting'),
        () -> data.set('foo')
      )
    ).renderWithoutAssert();
  }
}

class Suspendable extends Component {
  @prop var test:(comp:Suspendable)->Void = null;
  @prop var ready:Bool;
  @prop var makeReady:()->Void;
  public var ref:String = null;

  @effect
  public function maybeRunTest() {
    if (ready && test != null) test(this);
  }

  function render() {
    return if (!ready) {
      Suspend.suspend(resume -> {
        makeReady();
        resume();
      });
    } else {
      Text.text('done', result -> ref = result);
    }
  }
}
