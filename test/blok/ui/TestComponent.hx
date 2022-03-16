package blok.ui;

import impl.RootWidget;
import impl.TestingPlatform;
import impl.Node;
import haxe.ds.Option;

using Medic;
using medic.VNodeAssert;
using impl.Tools;

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
    var root = TestingPlatform.mount();
    var tests:Array<()->Void> = [];
    var expected:Option<String> = None;

    function check(comp:LazyComponent) {
      switch expected {
        case None:
          Assert.fail('Lazy component updated when it should not have');
        case Some(v):
          comp.stringifyWidget().equals(v);
      }
    }

    function test(foo, bar, e:Option<String>) return () -> {
      var next = tests.shift();
      if (next == null) next = done;
      expected = e;

      var vn = LazyComponent.node({
        foo: foo,
        bar: bar,
        test: check
      });

      render(root, vn, next);
    }

    tests = [
      test('foo', 'bar', None),
      test('foo', 'bar', None),
      test('foo', 'bin', Some('foo | bin')),
      test('bif', 'bin', Some('bif | bin')),
    ];

    test('foo', 'bar', Some('foo | bar'))();
  }

  @:test('Keys work')
  @:test.async
  function testKeys(done) {
    var root = TestingPlatform.mount();
    var one = Node.text('one', 'one');
    var two = Node.text('two', 'two');
    var three = Node.text('three', 'three');
    var oneComp:Widget = null;
    var twoComp:Widget = null;
    var threeComp:Widget = null;

    function test6() {
      render(root, ChildrenComponent.node({
        children: [],
        test: comp -> {
          var children = comp.getChildren();
          
          children.length.equals(0);

          done();
        }
      }));
    }

    function test5() {
      render(root, ChildrenComponent.node({
        children: [ three, two, Node.text('interloper'), one ],
        test: comp -> {
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
      render(root, ChildrenComponent.node({
        children: [ three, two, one ],
        test: comp -> {
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
      render(root, ChildrenComponent.node({
        children: [ two, three, one ],
        test: comp -> {
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
      render(root, ChildrenComponent.node({
        children: [ one, three, two ],
        test: comp -> {
          var children = comp.getChildren();
          
          children.length.equals(3);

          oneComp.equals(children[0]);
          twoComp.equals(children[2]);
          threeComp.equals(children[1]);
          
          test3();
        }
      }));
    }

    render(root, ChildrenComponent.node({
      children: [ one, two, three ],
      test: comp -> {
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

  function render(root:RootWidget, vn:VNode, ?next) {
    root.getPlatform().schedule(effects -> {
      root.setChildren([ vn ]);
      root.performUpdate(effects);
      if (next != null) effects.register(next);
    });
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
    return Node.text(content, null, result -> ref = result);
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
    return Node.text(foo + ' | ' + bar);
  }
}

class ChildrenComponent extends Component {
  @prop var children:Array<VNode>;
  @prop var test:(comp:ChildrenComponent)->Void = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(this);
  }
  
  public function render() {
    return children;
  }
}
