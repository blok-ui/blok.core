import helpers.*;

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
}
