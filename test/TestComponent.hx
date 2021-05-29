import blok.TextComponent;
import blok.ChildrenComponent;
import blok.VNode;
import haxe.Exception;
import haxe.ds.Option;
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
    }).toResult().renders('foo', done);
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
    }).toResult().renderWithoutAssert();
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
        e.message.equals('Was caught : blok.ChildrenComponent -> ExceptionBoundary -> ThrowsException');
        done();
      },
      fallback: () -> Text.text('Fell back'),
      build: () -> ThrowsException.node({})
    }).toResult().renderWithoutAssert();
  }

  @:test('Components catch exceptions and have fallbacks')
  @:test.async
  function testExceptionBoundariesWithFallback(done) {
    ExceptionBoundary.node({
      handle: e -> {
        // noop
      },
      fallback: () ->  Text.text('Fell back'),
      build: () -> ThrowsException.node({})
    }).toResult().renders('Fell back', done);
  }

  @:test('If the fallback throws an exception things do not die')
  @:test.async
  function testExceptionBoundariesWithFallbackFailing(done) {
    try {
      ExceptionBoundary.node({
        handle: e -> {
          // noop
        },
        fallback: () -> ThrowsException.node({}),
        build: () -> ThrowsException.node({})
      }).toResult().renders('Fell back', () -> {
        Assert.fail('Should not have rendered');
        done();
      });
    } catch (e) {
      Assert.pass();
      done();
    }
  }

  @:test('Keys work')
  @:test.async
  function testKeys(done) {
    var testCtx = new TestContext();
    var one = Text.text('one', null, 'one');
    var two = Text.text('two', null, 'two');
    var three = Text.text('three', null, 'three');
    var oneComp:Component = null;
    var twoComp:Component = null;
    var threeComp:Component = null;

    function test6() {
      testCtx.render(ChildrenComponent.node({
        children: [],
        onupdate: comp -> {
          var children = comp.getChildComponents();
          
          children.length.equals(0);

          done();
        }
      }));
    }

    function test5() {
      testCtx.render(ChildrenComponent.node({
        children: [ three, two, Text.text('interloper'), one ],
        onupdate: comp -> {
          var children = comp.getChildComponents();
          
          children.length.equals(4);

          oneComp.equals(children[3]);
          twoComp.equals(children[1]);
          threeComp.equals(children[0]);
          
          test6();
        }
      }));
    }
    
    function test4() {
      testCtx.render(ChildrenComponent.node({
        children: [ three, two, one ],
        onupdate: comp -> {
          var children = comp.getChildComponents();
          
          children.length.equals(3);

          oneComp.equals(children[2]);
          twoComp.equals(children[1]);
          threeComp.equals(children[0]);
          
          test5();
        }
      }));
    }

    function test3() {
      testCtx.render(ChildrenComponent.node({
        children: [ two, three, one ],
        onupdate: comp -> {
          var children = comp.getChildComponents();
          
          children.length.equals(3);

          oneComp.equals(children[2]);
          twoComp.equals(children[0]);
          threeComp.equals(children[1]);
          
          test4();
        }
      }));
    }

    function test2() {
      testCtx.render(ChildrenComponent.node({
        children: [ one, three, two ],
        onupdate: comp -> {
          var children = comp.getChildComponents();
          
          children.length.equals(3);

          oneComp.equals(children[0]);
          twoComp.equals(children[2]);
          threeComp.equals(children[1]);
          
          test3();
        }
      }));
    }

    testCtx.render(ChildrenComponent.node({
      children: [ one, two, three ],
      onupdate: comp -> {
        var children = comp.getChildComponents();
        
        oneComp = children[0];
        twoComp = children[1];
        threeComp = children[2];

        children[0].getComponentKey().equals(one.key);
        children[1].getComponentKey().equals(two.key);
        children[2].getComponentKey().equals(three.key);

        test2();
      }
    }));
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
  
  public function render():VNode {
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

  public function render():VNode {
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

class ThrowsException extends Component {
  public function render():VNode {
    throw new Exception('Was caught');
  }
}
