package blok.macro.build.field;

using blok.macro.MacroTools;

class ActionFieldBuilder implements Builder {
  public function new() {}

  public function parse(builder:ClassBuilder) {
    for (field in builder.findFieldsByMeta(':action')) switch field.kind {
      case FFun(f):
        if (f.ret != null && f.ret != macro:Void) {
          field.pos.error(':action methods cannot return anything');
        }
        var expr = f.expr;
        f.expr = macro blok.signal.Action.run(() -> $expr);
      default:
        field.pos.error(':action fields must be functions');
    }
  }

  public function apply(builder:ClassBuilder) {}
}
