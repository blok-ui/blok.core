package blok.macro.builder;

import haxe.macro.Expr;

using blok.macro.MacroTools;

class ResourceFieldBuilder implements Builder {
  public final priority:BuilderPriority = Normal;

  public function new() {}

  public function apply(builder:ClassBuilder) {
    for (field in builder.findFieldsByMeta(':resource')) {
      parseField(builder, field.getMetadata(':resource'), field);
    }
  }

  function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
    switch field.kind {
      case FVar(t, e):
        if (t == null) field.pos.error(':resource fields cannot infer return types');
        if (e == null) field.pos.error(':resource fields require an expression');
        if (!field.access.contains(AFinal)) field.pos.error(':resource fields must be final');
  
        var name = field.name;
        var getterName = 'get_$name';
        var backingName = '__backing_$name';
        var createName = '__create_$name';
  
        field.name = createName;
        field.meta.push({ name: ':noCompletion', params: [], pos: (macro null).pos });
        field.kind = FFun({
          args: [],
          ret: macro:blok.suspense.Resource<$t>,
          expr: macro return new blok.suspense.Resource<$t>(() -> $e)
        });
  
        builder.addField({
          name: name,
          access: field.access,
          kind: FProp('get', 'never', macro:blok.suspense.Resource<$t>),
          pos: (macro null).pos
        });
  
        builder.add(macro class {
          var $backingName:Null<blok.suspense.Resource<$t>> = null;
  
          function $getterName():blok.suspense.Resource<$t> {
            blok.debug.Debug.assert(this.$backingName != null);
            return this.$backingName;
          }
        });

        builder.addHook('init:late', macro this.$backingName = this.$createName());
      default:
        meta.pos.error(':resource fields cannot be methods');
    }
  }
}
