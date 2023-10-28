package blok.macro;

import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using haxe.macro.Tools;

typedef PropField = {
  public final name:String;
  public final type:ComplexType;
  public final optional:Bool;
} 

class ClassBuilder {
  public static function fromContext() {
    return new ClassBuilder({
      type: Context.getLocalType(),
      fields: Context.getBuildFields(),
      builders: []
    });
  }

  final type:Type;
  final fields:Array<Field>;
  final builders:Array<Builder>;
  
  var propCollection:Map<String, Array<Field>> = [];
  var hookCollection:Map<String, Array<Expr>> = [];
  var newFields:Array<Field> = [];

  public function new(options) {
    this.builders = options.builders;
    this.fields = options.fields;
    this.type = options.type;
  }

  public function getType() {
    return type;
  }

  public function getComplexType() {
    return type.toComplexType();
  }

  public function getTypePath():TypePath {
    var cls = getClass();
    return {
      pack: cls.pack,
      name: cls.name
    };
  }

  public function getClass() {
    return switch type {
      case TInst(t, _): t.get();
      default: throw 'assert';
    }
  }

  public function getFields() {
    return fields;
  }

  public function add(t:TypeDefinition) {
    mergeFields(t.fields);
    return this;
  }

  public function addField(f:Field) {
    newFields.push(f);
    return this;
  }

  public function addHook(key:String, ...exprs:Expr) {
    var hooks = hookCollection.get(key) ?? [];
    hooks = hooks.concat(exprs);
    hookCollection.set(key, hooks);
  }

  public function addProp(key:String, ...newFields:PropField) {
    var pos = (macro null).pos;
    var props = propCollection.get(key) ?? [];
    var fields:Array<Field> = newFields.toArray().map(f -> ({
      name: f.name,
      kind: FVar(f.type),
      meta: f.optional ? [{name: ':optional', pos: pos}] : [],
      pos: pos
    }:Field));
    props = props.concat(fields);
    propCollection.set(key, props);
  }

  public function getHook(key) {
    return hookCollection.get(key) ?? [];
  }

  public function getProps(key) {
    return propCollection.get(key) ?? [];
  }

  public function mergeFields(fields:Array<Field>) {
    newFields = newFields.concat(fields);
    return this;
  }

  public function merge(builder:ClassBuilder) {
    mergeFields(builder.newFields);
    return this;
  }

  public function findField(name:String):Maybe<Field> {
    return switch fields.find(f -> f.name == name) {
      case null: None;
      case field: Some(field);
    }
  }

  public function findFieldsByMeta(name:String) {
    return fields.filter(f -> f.meta.exists(m -> m.name == name));
  }

  function apply(priority:BuilderPriority) {
    var selected = builders.filter(b -> b.priority == priority);
    for (builder in selected) builder.apply(this);
  }

  public function export() {
    apply(Before);
    apply(Normal);
    apply(Late);
    return fields.concat(newFields);
  }
}
