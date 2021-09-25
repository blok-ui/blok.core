import blok.Widget;
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
    var tests:Array<()->Void> = [];
    var expected:Option<String> = None;

    function check(comp:LazyComponent) {
      switch expected {
        case None:
          Assert.fail('Lazy component updated when it should not have');
        case Some(v):
          Text.stringifyWidget(comp).equals(v);
      }
    }

    function test(foo, bar, e:Option<String>) return () -> {
      var next = tests.shift();
      if (next == null) next = done;
      expected = e;
      testCtx.render(LazyComponent.node({
        foo: foo,
        bar: bar,
        test: check
      }), next);
    }

    tests = [
      test('foo', 'bar', None),
      test('foo', 'bar', None),
      test('foo', 'bin', Some('foo | bin')),
      test('bif', 'bin', Some('bif | bin')),
    ];

    test('foo', 'bar', Some('foo | bar'))();
  }

  @:test('Components catch exceptions')
  @:test.async
  function testExceptionBoundaries(done) {
    ExceptionBoundary.node({
      handle: e -> {
        e.message.equals('Was caught : blok.FragmentWidget -> ExceptionBoundary -> ThrowsException');
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
    var one = Text.text('one', 'one');
    var two = Text.text('two', 'two');
    var three = Text.text('three', 'three');
    var oneComp:Widget = null;
    var twoComp:Widget = null;
    var threeComp:Widget = null;

    function test6() {
      testCtx.render(ChildrenComponent.node({
        children: [],
        onupdate: comp -> {
          var children = comp.getChildren();
          
          children.length.equals(0);

          done();
        }
      }));
    }

    function test5() {
      testCtx.render(ChildrenComponent.node({
        children: [ three, two, Text.text('interloper'), one ],
        onupdate: comp -> {
          var children = comp.getChildren();
          
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
          var children = comp.getChildren();
          
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
          var children = comp.getChildren();
          
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
          var children = comp.getChildren();
          
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
        var children = comp.getChildren();
        
        oneComp = children[0];
        twoComp = children[1];
        threeComp = children[2];

        children[0].getWidgetKey().equals(one.key);
        children[1].getWidgetKey().equals(two.key);
        children[2].getWidgetKey().equals(three.key);

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
    return { content: content };
  }
  
  public function render() {
    return Text.text(content, null, result -> ref = result);
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

class ThrowsException extends Component {
  public function render() {
    throw new Exception('Was caught');
  }
}
