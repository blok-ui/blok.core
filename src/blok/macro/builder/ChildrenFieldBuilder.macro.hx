package blok.macro.builder;

using Lambda;
using blok.macro.MacroTools;

class ChildrenFieldBuilder implements Builder {
  public final priority:BuilderPriority = Late;

  public function new() {}

  public function apply(builder:ClassBuilder) {
    var children = builder.findFieldsByMeta(':children');
    switch children {
      case [field]:
        var prop = builder.getProps('new').find(p -> p.name == field.name);
        if (prop == null) {
          field.pos.error('Invalid target for :children');
        }
        prop.meta.push({ name: ':children', params: [], pos: prop.pos });
      case []:
        // noop
      case tooMany:
        tooMany[1].pos.error('Only one field can be marked with :children');
    }
  }
}
