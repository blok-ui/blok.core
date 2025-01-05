package blok.html;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import kit.macro.ClassFieldCollection;

using StringTools;
using haxe.macro.Tools;
using kit.macro.Tools;

function buildGeneric() {
	return switch Context.getLocalType() {
		case TInst(_, [attrType]):
			buildAttrNameEnum(attrType);
		default:
			throw 'assert';
	}
}

function buildAttrNameEnum(attrType:Type) {
	var suffix = attrType.stringifyTypeForClassName();
	var pack = ['blok', 'html'];
	var name = 'AttributeName_$suffix';
	var path:TypePath = {pack: pack, name: name, params: []};

	if (path.typePathExists()) return TPath(path);

	var enumFields = new ClassFieldCollection([]);

	switch attrType.follow() {
		case TAnonymous(a):
			var refFields = a.get().fields;
			for (field in refFields) {
				var refName = field.name;
				if (refName.startsWith('on')) {
					refName = refName.substr(2);
				}

				var name = refName.charAt(0).toUpperCase() + refName.substr(1);
				var value = switch field.meta.extract(':html') {
					case [meta]:
						switch meta.params {
							case [{expr: EConst(CString(s, _)), pos: _}]:
								s;
							default:
								field.name.toLowerCase();
						}
					default:
						field.name.toLowerCase();
				}

				enumFields.add(macro class {
					final $name = $v{value};
				});
			}
		default:
			Context.currentPos().error('Invalid target');
	}

	Context.defineType({
		pack: pack,
		name: name,
		fields: enumFields.export(),
		kind: TDAbstract(
			macro :String,
			[AbEnum],
			[macro :String],
			[macro :String]
		),
		pos: (macro null).pos
	});

	return TPath(path);
}
