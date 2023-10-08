package blok.html.parse;

// import blok.html.TagBuilder;
import blok.parse.*;
// import haxe.macro.Context;
// import haxe.macro.Expr;

using Lambda;

class HtmlGenerator {
  public static function instance() {
    static var generator:Null<Generator> = null;
    if (generator == null) generator = new Generator(new TagContext(Root, [
      'blok.html.Html',
      'blok.html.Svg'
    ]));
    return generator;
  }
}

// class HtmlGenerator extends Generator {
//   public static function instance() {
//     static var generator:Null<HtmlGenerator> = null;
//     if (generator == null) generator = new HtmlGenerator();
//     return generator;
//   }

//   public function new() {}

//   function generateBuiltinNode(name:Located<String>, attributes:Array<Attribute>, children:Array<Node>, pos:Position):Expr {
//     var svgTags = getTags('blok.html.SvgTags');
//     var tag = name.value;
//     var cls = svgTags.exists(t -> t.name == tag) ? 'Svg' : 'Html';

//     attributes = attributes.concat(extractAttributes(children));

//     var e = macro @:pos(name.pos) blok.html.$cls.$tag;
//     #if (haxe_ver >= 4.1)
//     if (Context.containsDisplayPosition(e.pos)) {
//       e = {expr: EDisplay(e, DKMarked), pos: e.pos};
//     }
//     #end

//     return macro $e(${{
//       expr: EObjectDecl(attributesToObjectFields(attributes).map(f -> {
//         if (f.field == 'class') {
//           f.field = 'className';
//         }
//         return f;
//       })),
//       pos: name.pos // ??
//     }}, ...$a{children.map(generateNode)});
//   }
// }
