package blok.macro.build;

class SimpleBuilder implements Builder {
  public final priority:BuilderPriority;

  final doApply:Null<(builder:ClassBuilder)->Void>;

  public function new(props:{
    ?priority:BuilderPriority,
    ?apply:(builder:ClassBuilder)->Void
  }) {
    this.priority = props.priority ?? Normal;
    this.doApply = props.apply;
  }

  public function apply(builder:ClassBuilder) {
    if (doApply != null) doApply(builder);
  }
}
