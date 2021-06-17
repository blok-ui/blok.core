package blok;

enum VNodeKind {
  VSingle(node:VNode);
  VGroup(nodes:Array<VNode>);
  VNone;
}

abstract VNodeResult(VNodeKind) {
  @:from public static function ofArray(nodes:Array<VNode>) {
    return new VNodeResult(VGroup(nodes));
  }

  @:from public static function ofSingle(node:Null<VNode>) {
    return new VNodeResult(node == null ? VNone : VSingle(node));
  }
  
  public function new(kind) {
    this = kind;
  }

  public function unwrap():VNodeKind {
    return this;
  }

  @:to public function toArray():Array<VNode> {
    return switch this {
      case null | VNone: [];
      case VSingle(node): [ node ];
      case VGroup(nodes): nodes;
    }
  }
}
