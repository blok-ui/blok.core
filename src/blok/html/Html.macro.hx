package blok.html;

import blok.parse.*;
import haxe.macro.Expr;

class Html {
  public static function view(expr:Expr) {
    static var generator:Null<Generator> = null;
    
    if (generator == null) {
      generator = new Generator(new TagContext(Root, [
        'blok.html.Html',
        'blok.html.Svg'
      ]));
    }

    var parser = new Parser(expr, {
      generateExpr: generator.generate
    });
    
    return parser.toExpr();
  }
}
