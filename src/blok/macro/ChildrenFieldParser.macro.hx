package blok.macro;

import kit.macro.*;

using Lambda;
using kit.macro.Tools;

class ChildrenFieldParser implements Parser {
	public final priority:Priority = Late;

	public function new() {}

	public function apply(builder:ClassBuilder) {
		var children = builder.findFieldsByMeta(':children');
		switch children {
			case [field]:
				var prop = builder.hook(Init).getProps().find(prop -> prop.name == field.name);
				if (prop == null) {
					field.pos.error('Invalid target for :children');
				}
				prop.meta.push({name: ':children', params: [], pos: prop.pos});
			case []:
			// noop
			case tooMany:
				tooMany[1].pos.error('Only one field can be marked with :children');
		}
	}
}
