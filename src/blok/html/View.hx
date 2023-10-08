package blok.html;

macro function view(expr:haxe.macro.Expr) {
  var generator = blok.html.parse.HtmlGenerator.instance();
  var parser = new blok.parse.Parser(expr, {
    generateExpr: generator.generate
  });
  return parser.toExpr();
}
