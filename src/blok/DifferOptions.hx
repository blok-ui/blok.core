package blok;

typedef DifferOptions = {
  public final ?createPlaceholder:(component:Component)->Null<Component>;
  public final ?onInitialize:(component:Component)->Void;
  public final ?onUpdate:(component:Component, previous:Array<Component>)->Void;
}
