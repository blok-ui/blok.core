package blok.html;

import haxe.macro.Context;
import blok.macro.FieldBuilder;

function build() {
	var enumFields = new FieldBuilder(Context.getBuildFields());
	var names = Context.getType('blok.html.HtmlAttributes.GlobalAttr');

	switch names {
		case TType(t, _):
			switch t.get().type {
				case TAnonymous(a):
					var refFields = a.get().fields;
					for (field in refFields) {
						var name = field.name.charAt(0).toUpperCase() + field.name.substr(1);
						var value = switch field.meta.extract(':html') {
							case [meta]: switch meta.params {
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
					throw 'assert';
			}
		default:
			throw 'assert';
	}

	return enumFields.export();
}
