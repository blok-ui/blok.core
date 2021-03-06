import haxe.ds.Option;
import blok.Html;
import blok.Context;
import blok.Component;
import helpers.TestContext;

using Medic;
using helpers.VNodeAssert;

class TestComponent implements TestCase {
  public function new() {}

  @:test('Components render to html')
  @:test.async
  public function testSimple(done) {
    SimpleComponent.node({
      content: 'foo',
      className: 'bar'
    }).renders('<p class="bar">foo</p>', done);
  }

  @:test('Components can update themselves')
  @:test.async
  public function testUpdate(done) {
    var tests = [
      (comp:SimpleComponent) -> {
        comp.ref.outerHTML.equals('<p class="bar">foo</p>');
        comp.setContent('bin');
      },
      (comp:SimpleComponent) -> {
        comp.ref.outerHTML.equals('<p class="bar">bin</p>');
        done();
      }
    ];
    SimpleComponent.node({
      content: 'foo',
      className: 'bar',
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
          testCtx.el.innerHTML.equals(v);
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
}

class SimpleComponent extends Component {
  @prop public var className:String;
  @prop public var content:String;
  @prop var test:(comp:SimpleComponent)->Void = null;
  public var ref:js.html.Element = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(this);
  }

  @update
  public function setContent(content) {
    return UpdateState({ content: content });
  }
  
  override function render(context) {
    return Html.h('p', { className: className }, [ Html.text(content) ], node -> ref = cast node);
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

  override function render(context:Context) {
    return Html.text(foo + ' | ' + bar);
  }
}
