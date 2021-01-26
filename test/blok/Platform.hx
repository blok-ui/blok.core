package blok;

import js.html.Node;
import blok.core.Context;
import blok.core.Differ;
import blok.core.VNode;

class Platform {
  public static function mount(el:Node, build:(context:Context<Node>)->VNode<Node>) {
    var context:Context<Node> = new Context(new Engine());
    Differ.renderWithSideEffects(el, [ build(context) ], null, context);
  }
}
