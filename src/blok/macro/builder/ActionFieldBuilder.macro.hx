package blok.macro.builder;

import haxe.macro.Context;

using blok.macro.MacroTools;

class ActionFieldBuilder implements Builder {
  public final priority:BuilderPriority = Normal;

  public function new() {}

  public function apply(builder:ClassBuilder) {
    for (field in builder.findFieldsByMeta(':action')) {
      Context.warning(':action fields are no longer needed. Just use normal methods.', field.pos);
    }

    // for (field in builder.findFieldsByMeta(':action')) switch field.kind {
    //   case FFun(f):
    //     if (f.ret != null && f.ret != macro:Void) {
    //       field.pos.error(':action methods cannot return anything');
    //     }
    //     var expr = f.expr;
    //     f.expr = macro blok.signal.Action.run(() -> $expr);
    //   default:
    //     field.pos.error(':action fields must be functions');
    // }
  }
}
