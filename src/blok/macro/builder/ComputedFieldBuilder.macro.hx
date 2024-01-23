package blok.macro.builder;

import haxe.macro.Expr;

using blok.macro.MacroTools;

class ComputedFieldBuilder implements Builder {
  public final priority:BuilderPriority = Normal;

  public function new() {}

  public function apply(builder:ClassBuilder) {
    for (field in builder.findFieldsByMeta(':computed')) {
      parseField(builder, field.getMetadata(':computed'), field);
    }
  }

  function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
    switch field.kind {
      case FVar(t, e):
        if (t == null) {
          field.pos.error('@:computed field require an explicit type');
        }
        if (e == null) {
          field.pos.error('@:computed fields require an expression');
        }
        if (!field.access.contains(AFinal)) {
          field.pos.error('@:computed fields must be final');
        }

        var name = field.name;

        field.kind = FVar(macro:blok.signal.Computation<$t>, null);
        builder.addHook('init', macro this.$name = new blok.signal.Computation<$t>(() -> $e));
      default:
        meta.pos.error('Invalid field for :computed');
    }
  }
}
