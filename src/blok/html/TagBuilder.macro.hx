package blok.html;

import blok.macro.ClassBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
// using blok.macro.MacroTools;
using haxe.macro.Tools;

function build(typeName:String) {
  var tags = getTags(typeName);
  var builder = ClassBuilder.fromContext();

  for (tag in tags) {
    var name = tag.name;
    var nameType = '__componentType_$name';
    var props = tag.type.toComplexType();

    switch tag.kind {
      case TagVoid:
        builder.add(macro class {
          private static final $nameType = new kit.UniqueId();
          public static function $name(props:$props & blok.html.HtmlEvents, ?key) {
            return new blok.ui.VRealNode($i{nameType}, $v{name}, props, null, key);
          }
        });
      default:
        builder.add(macro class {
          private static final $nameType = new kit.UniqueId();
          public static function $name(props:$props & blok.html.HtmlEvents & { ?key:blok.diffing.Key }, ...children:blok.ui.Child) {
            return new blok.ui.VRealNode($i{nameType}, $v{name}, props, children.toArray(), props.key);
          }
        });
    }

  }

  return builder.export();
}

private enum abstract TagKind(String) to String {
  var TagVoid = 'void';
  var TagNormal = 'normal';
  var TagOpaque = 'opaque';
}

private typedef TagInfo = {
  name:String,
  kind:TagKind,
  type:Type,
  element:ComplexType
}

@:persistent private final tagInfos:Map<String, Array<TagInfo>> = [];

private function getTags(typeName:String):Array<TagInfo> {
  if (tagInfos.exists(typeName)) return tagInfos.get(typeName);

  var type = Context.getType(typeName);
  var tags:Array<TagInfo> = [];
  var groups = switch type {
    case TType(t, params): switch (t.get().type) {
        case TAnonymous(a): a.get().fields;
        default: throw 'assert';
      }
    default:
      throw 'assert';
  }

  for (group in groups) {
    var kind:TagKind = cast group.name;
    var fields = switch group.type {
      case TAnonymous(a): a.get().fields;
      default: throw 'assert';
    }
    for (f in fields) {
      var element = if (Context.defined('js') && !Context.defined('nodejs')) 
        switch f.meta.extract(':element') {
          case []: 
            switch f.type {
              case TType(_.get() => {module: 'blok.html.HtmlAttributes', name: name}, params):
                var prefix = switch name.split('Attr') {
                  case ['Global', '']: '';
                  case [name, '']: name;
                  default: throw 'assert';
                }
                Context.getType('js.html.${prefix}Element').toComplexType();
              default: 
                throw 'assert';
            }
          case [{params: [path]}]:
            Context.getType(path.toString()).toComplexType();
          default:
            Context.error('Invalid @:element', f.pos);
            throw 'assert';
        }
      else {
        macro:Dynamic;
      }
      tags.push({
        name: f.name,
        type: f.type,
        kind: kind,
        element: element
      });
    }
  }

  tagInfos.set(typeName, tags);

  return tags;
}

private function getHtmlName(f:ClassField) {
  var htmlName = switch f.meta.extract(':html') {
    case []: 
      f.name;
    case [{params:[ { expr: EConst(CString(name, _)), pos: _ } ]}]: 
      name;
    default:
      Context.error('Invalid argument for :html', f.meta.extract(':html')[0].pos);
  }
}
