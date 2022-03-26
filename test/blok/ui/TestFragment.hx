package blok.ui;

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
    // Note: the extra space in `before  after` is expected --
    // that indicates an empty node.
    Node.fragment(
      Node.text('before'),
      Node.fragment(),
      Node.text('after')
    ).renders('before  after', done);
  }
}
