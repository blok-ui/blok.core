import haxe.Exception;
import haxe.ds.Option;
import blok.VNode;
import blok.Text;
import blok.Component;
import helpers.TestContext;

using Medic;
using helpers.VNodeAssert;

class TestComponent implements TestCase {
  public function new() {}

  @:test('Components render')
  @:test.async
  public function testSimple(done) {
    SimpleComponent.node({
      content: 'foo',
    }).renders('foo', done);
  }

  @:test('Components can update themselves')
  @:test.async
  public function testUpdate(done) {
    var tests = [
      (comp:SimpleComponent) -> {
        comp.ref.equals('foo');
        comp.setContent('bin');
      },
      (comp:SimpleComponent) -> {
        comp.ref.equals('bin');
        done();
      }
    ];
    SimpleComponent.node({
      content: 'foo',
      test: comp -> {
        var test = tests.shift();
        if (test != null) test(comp);
      }
    }).renderWithoutAssert();
  }

  @:test('Components can be lazy')
  @:test.async
  public function testLazy(done) {
    var testCtx = new TestContext();
    var rendered = 0;
    var expected:Option<String> = None;

    function tester(_) {
      switch expected {
        case Some(v):
          rendered++;
          testCtx.root.toString().equals(v);
        case None:
          Assert.fail('Lazy component updated when it should not have');
      }
      if (rendered == 3) {
        done();
      }
    }

    function comp(foo, bar, e) {
      expected = e;  
      return LazyComponent.node({
        foo: foo,
        bar: bar,
        test: tester
      });
    };

    testCtx.render(comp('foo', 'bar', Some('foo | bar')));
    testCtx.render(comp('foo', 'bar', None));
    testCtx.render(comp('foo', 'bar', None));
    testCtx.render(comp('foo', 'bin', Some('foo | bin')));
    testCtx.render(comp('bif', 'bin', Some('bif | bin')));
  }

  @:test('Components catch exceptions')
  @:test.async
  function testExceptionBoundaries(done) {
    ExceptionBoundary.node({
      handle: e -> {
        e.message.equals('Was caught : blok.ChildrenComponent -> ExceptionBoundary');
        done();
      },
      fallback: () -> {
        return Text.text('Fell back');
      },
      build: () -> {
        throw new Exception('Was caught');
        return Text.text('Should not render');
      }
    }).renderWithoutAssert();
  }

  @:test('Components catch exceptions and have fallbacks')
  @:test.async
  function testExceptionBoundariesWithFallback(done) {
    ExceptionBoundary.node({
      handle: e -> {
        // noop
      },
      fallback: () -> {
        return Text.text('Fell back');
      },
      build: () -> {
        throw new Exception('Was caught');
        return Text.text('Should not render');
      }
    }).renders('Fell back', done);
  }
}

class SimpleComponent extends Component {
  @prop public var content:String;
  @prop var test:(comp:SimpleComponent)->Void = null;
  public var ref:String = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(this);
  }

  @update
  public function setContent(content) {
    return UpdateState({ content: content });
  }
  
  public function render() {
    return Text.text(content, result -> ref = result);
  }
}

@lazy
class LazyComponent extends Component {
  @prop var foo:String;
  @prop var bar:String;
  @prop var test:(comp:LazyComponent)->Void;

  @effect
  public function runTest() {
    test(this);
  }

  public function render() {
    return Text.text(foo + ' | ' + bar);
  }
}

class ExceptionBoundary extends Component {
  @prop var build:()->VNode;
  @prop var fallback:()->VNode;
  @prop var handle:(e:Exception)->Void;
  
  override function componentDidCatch(exception:Exception) {
    handle(exception);
    return fallback();
  }

  public function render() {
    return build();
  }
}
