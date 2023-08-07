package blok.html.parse;

macro function toBlok(expr) {
  return blok.html.parse.Parser.parseExpr(expr);
}
