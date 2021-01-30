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
}
