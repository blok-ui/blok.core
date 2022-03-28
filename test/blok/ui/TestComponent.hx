package blok.ui;

import impl.TestingObject;
import impl.TestingRootWidget;
import impl.TestingPlatform;
import impl.Node;
import haxe.ds.Option;

using Medic;
using medic.WidgetAssert;

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
          root.toString().equals(v);
      }
    }

    function test(foo, bar, e:Option<String>) return () -> {
      var next = tests.shift();
      if (next == null) next = done;
      expected = e;

      var widget = LazyComponent.node({
        foo: foo,
        bar: bar,
        test: check
      });

      render(root, widget, next);
    }

    tests = [
      test('foo', 'bar', None),
      test('foo', 'bar', None),
      test('foo', 'bin', Some('foo | bin')),
      test('bif', 'bin', Some('bif | bin')),
    ];

    test('foo', 'bar', Some('foo | bar'))();
  }

  // @todo: this needs to be way more robust.
  @:test('Hydration works')
  @:test.async
  public function testHydration(done) {
    var root = new TestingObject('');
    var object = new TestingObject('');
    object.append(new TestingObject('foo'));
    object.append(new TestingObject('bar'));
    
    root.append(object);
    root.toString().equals('foo bar');

    TestingPlatform
      .hydrate(root, Node.wrap(
        Node.text('foo'),
        Node.text('bar')
      ), (obj) -> {
        (root == obj).isTrue();
        obj.toString().equals('foo bar');
        done();
      });
  }

  @:test('Keys work')
  @:test.async
  function testKeys(done) {
    var root = TestingPlatform.mount();
    var one = Node.text('one', 'one');
    var two = Node.text('two', 'two');
    var three = Node.text('three', 'three');
    var oneComp:Element = null;
    var twoComp:Element = null;
    var threeComp:Element = null;

    function test6() {
      render(root, ChildrenComponent.node({
        children: [],
        test: element -> {
          var len = 0;
          element.visitChildren(_ -> len++);
          len.equals(0);
          done();
        }
      }));
    }

    function test5() {
      render(root, ChildrenComponent.node({
        children: [ three, two, Node.text('interloper'), one ],
        test: element -> {
          var children = [];
          element.visitChildren(child -> children.push(child));
          
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
        test: element -> {
          var children = [];
          element.visitChildren(child -> children.push(child));
          
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
        test: element -> {
          var children = [];
          element.visitChildren(child -> children.push(child));
          
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
        test: element -> {
          var children = [];
          element.visitChildren(child -> children.push(child));
          
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
      test: element -> {
        var children = [];
        element.visitChildren(child -> children.push(child));
        
        oneComp = children[0];
        twoComp = children[1];
        threeComp = children[2];

        children[0].widget.key.equals(one.key);
        children[1].widget.key.equals(two.key);
        children[2].widget.key.equals(three.key);

        test2();
      }
    }));
  }

  function render(root:TestingRootElement, widget:Widget, ?next) {
    root.setChild(Node.wrap(widget), next);
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
    return Node.text(content, null, result -> ref = result.toString());
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
  @prop var children:Array<Widget>;
  @prop var test:(comp:Element)->Void = null;

  @effect
  public function maybeRunTest() {
    if (test != null) test(childElement);
  }
  
  public function render() {
    return Node.fragment(...children);
  }
}
