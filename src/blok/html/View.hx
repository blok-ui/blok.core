package blok.html;

/**
  Create a VNode tree using JSX-like markup literals.

  Warning: still a very experimental feature. Completion is currently
  very broken. For the moment, it's best used in situations where copying
  HTML (such as for an SVG icon) is useful.
**/
macro function view(expr:haxe.macro.Expr) {
  static var generator:Null<blok.parse.Generator> = null;
  
  if (generator == null) {
    generator = new blok.parse.Generator(new blok.parse.TagContext(Root, [
      'blok.html.Html',
      'blok.html.Svg'
    ]));
  }

  var parser = new blok.parse.Parser(expr, {
    generateExpr: generator.generate
  });
  
  return parser.toExpr();
}
