package blok.macro.builder;

import haxe.macro.Expr;

using blok.macro.MacroTools;

class AttributeFieldBuilder implements Builder {
  public final priority:BuilderPriority = Normal;

  public function new() {}

  public function apply(builder:ClassBuilder) {
    for (field in builder.findFieldsByMeta(':attribute')) {
      parseField(builder, field.getMetadata(':attribute'), field);
    }
  }

  function parseField(builder:ClassBuilder, meta:MetadataEntry, field:Field) {
    switch field.kind {
      case FVar(t, e) if (t == null):
        field.pos.error('Expected a type');
      case FVar(t, e):
        var name = field.name;
        var backingName = '__backing_$name';
        var getterName = 'get_$name';
  
        if (!field.access.contains(AFinal)) {
          field.pos.error(':attribute fields must be final.');
        }
        
        field.kind = FProp('get', 'never', t);
        
        var expr = switch e {
          case macro null: macro new blok.signal.Signal(null);
          default: e;
        };
  
        builder.add(macro class {
          @:noCompletion final $backingName:blok.signal.Signal<$t>;
  
          function $getterName():$t {
            return this.$backingName.get();
          }
        });

        builder.addProp('new', {
          name: name,
          type: t,
          optional: e != null
        });
        builder.addHook('init', if (e == null) {
          macro this.$backingName = props.$name;
        } else {
          macro @:pos(e.pos) this.$backingName = props.$name ?? $e;
        });
        builder.addHook('update', if (e == null) { 
          macro this.$backingName.set(props.$name);
        } else {
          macro @:pos(e.pos) this.$backingName.set(props.$name ?? $e);
        });
      default:
        meta.pos.error('Invalid field for :attribute');
    }
  }
}
