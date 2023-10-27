package blok.macro.build;

class SimpleBuilder implements Builder {
  final doParse:Null<(builder:ClassBuilder)->Void>;
  final doApply:Null<(builder:ClassBuilder)->Void>;

  public function new(props:{
    ?parse:(builder:ClassBuilder)->Void,
    ?apply:(builder:ClassBuilder)->Void
  }) {
    this.doParse = props.parse;
    this.doApply = props.apply;
  }

  public function parse(builder:ClassBuilder) {
    if (doParse != null) doParse(builder); 
  }

  public function apply(builder:ClassBuilder) {
    if (doApply != null) doApply(builder);
  }
}
