package blok.html.parse;

import blok.html.TagBuilder;
import haxe.macro.Expr;
import blok.parse.*;

using Lambda;

class HtmlGenerator extends Generator {
  public static function instance() {
    static var generator:Null<HtmlGenerator> = null;
    if (generator == null) generator = new HtmlGenerator();
    return generator;
  }

  public function new() {}

  function generateBuiltinNode(name:String, attributes:Array<Attribute>, children:Array<Node>, pos:Position):Expr {
    var svgTags = getTags('blok.html.SvgTags');
    var cls = svgTags.exists(tag -> tag.name == name) ? 'Svg' : 'Html';

    attributes = attributes.concat(extractAttributes(children));

    return macro @:pos(pos) blok.html.$cls.$name(${{
      expr: EObjectDecl(attributesToObjectFields(attributes).map(f -> {
        if (f.field == 'class') {
          f.field = 'className';
        }
        return f;
      })),
      pos: pos // ??
    }}, ...$a{children.map(generateNode)});
  }
}
