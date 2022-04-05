package blok.ui;

import blok.render.Object;
import impl.TestingPlatform;
import impl.Node;

using Medic;
using medic.WidgetAssert;

class TestFragment implements TestCase {
  public function new() {}

  @:test('Empty fragments work')
  @:test.async
  function testEmpty(done) {
    Node.fragment().renders('', done);
  }

  @:test('Fragments work')
  @:test.async
  function simpleFragments(done) {
    Node.fragment(
      Node.text('a'),
      Node.text('b'),
      Node.text('c'),
      Node.text('d')
    ).renders('a b c d', done);
  }

  @:test('Fragments will render relative to the elements around them')
  @:test.async
  function fragmentsInContext(done) {
    Node.fragment(
      Node.text('a'),
      Node.fragment(
        Node.text('b.1'),
        Node.text('b.2')
      ),
      Node.text('c')
    ).renders('a b.1 b.2 c', done);
  }

  @:test('Empty fragments render relative to the elements around them')
  @:test.async
  function testEmptyInContext(done) {
    Node.fragment(
      Node.text('before'),
      Node.fragment(),
      Node.text('after')
    ).renders('before <marker> after', done);
  }

  @:test('Fragments work when being rebuilt')
  @:test.async
  function canYouRebuildFragments(done) {
    var root = TestingPlatform.mount();
    var result = () -> (root.getObject():Object).toString();

    root.setChild(Node.wrap(
      Node.fragment(Node.text('a.1'), Node.text('a.2')),
      Node.fragment(),
      Node.fragment(Node.text('c.1'), Node.text('c.2'))
    ), () -> {
      result().equals('a.1 a.2 <marker> c.1 c.2');
      root.setChild(Node.wrap(
        Node.fragment(Node.text('a.1'), Node.text('a.2')),
        Node.text('foo'),
        Node.fragment(Node.text('b.1'), Node.text('b.2')),
        Node.text('bar'),
        Node.fragment(Node.text('c.1'), Node.text('c.2'))
      ), () -> {
        result().equals('a.1 a.2 foo b.1 b.2 bar c.1 c.2');
        done();
      });
    });
  }
}
