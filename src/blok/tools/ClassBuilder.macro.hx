package blok.tools;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type.ClassType;

using Lambda;

enum ClassBuilderHook {
  Init;
  Normal;
  After;
}

typedef ClassBuilderOption = {
  name:String,
  optional:Bool,
  ?handleValue:(expr:Expr)->Dynamic
} 

typedef FieldMetaHandler<Options:{}> = {
  public final name:String;
  public final hook:ClassBuilderHook;
  public final options:Array<ClassBuilderOption>;
  public function build(options:Options, builder:ClassBuilder, f:Field):Void;
}

typedef FieldFactory = {
  public final hook:ClassBuilderHook;
  public function build():TypeDefinition;
}

typedef ClassMetaHandler<Options:{}> = {
  public final name:String;
  public final hook:ClassBuilderHook;
  public final options:Array<ClassBuilderOption>;
  public function build(options:Options, builder:ClassBuilder, fields:Array<Field>):Void;
} 

class ClassBuilder {
  public inline static function fromContext() {
    return switch BuilderHelpers.getBuildFieldsSafe() {
      case Some(fields): 
        new ClassBuilder(
          Context.getLocalClass().get(),
          fields
        );
      case None:
        Context.error('Impossible to get builds fields now. Possible cause: https://github.com/HaxeFoundation/haxe/issues/9853', Context.currentPos());
        null;
    }
  }

  public final cls:ClassType;
  final fieldHandlers:Array<FieldMetaHandler<Dynamic>> = [];
  final classHandlers:Array<ClassMetaHandler<Dynamic>> = [];
  final fieldsToAdd:Array<FieldFactory> = [];
  var fields:Array<Field>;
  var ran:Bool = false;

  public function new(cls, fields) {
    this.cls = cls;
    this.fields = fields;
  }

  public function fieldExists(name:String) {
    return fields.exists(f -> f.name == name);
  }

  public function getField(name:String):Null<Field> {
    return fields.find(f -> f.name == name);
  }

  public inline function isInterface() {
    return cls.isInterface;
  }

  public function getTypePath():TypePath {
    return {
      pack: cls.pack,
      name: cls.name
    };
  }

  public function addFieldMetaHandler<Options:{}>(handler:FieldMetaHandler<Options>) {
    fieldHandlers.push(handler);
  }

  public function addClassMetaHandler<Options:{}>(handler:ClassMetaHandler<Options>) {
    classHandlers.push(handler);
  }

  public function addLater(build:() -> TypeDefinition, hook:ClassBuilderHook = After) {
    fieldsToAdd.push({
      build: build,
      hook: hook
    });
  }

  public inline function add(t:TypeDefinition) {
    addFields(t.fields);
  }

  public function addFields(fields:Array<Field>) {
    this.fields = this.fields.concat(fields);
  }

  public function export() {
    if (!ran) run();
    return fields;
  }

  public function run() {
    if (ran) return;
    ran = true;

    function parseFieldMetaHook(hook:ClassBuilderHook) {
      var copy = fields.copy();
      var cb = classHandlers.filter(h -> h.hook == hook);
      var fb = fieldHandlers.filter(h -> h.hook == hook);
      if (cb.length > 0) parseClassMeta(cb);
      if (fb.length > 0) for (f in copy) parseFieldMeta(f, fb);
      var toAdd = fieldsToAdd.filter(f -> f.hook == hook);
      if (toAdd.length > 0) for (handler in toAdd) add(handler.build());
    }
    
    parseFieldMetaHook(Init);
    parseFieldMetaHook(Normal);
    parseFieldMetaHook(After);
  }

  function parseFieldMeta(field:Field, fieldHandlers:Array<FieldMetaHandler<Dynamic>>) {
    if (field.meta == null) return;

    var toRemove:Array<MetadataEntry> = [];

    for (handler in fieldHandlers) {
      var match = (m:MetadataEntry) -> m.name == handler.name; 
      if (field.meta.exists(match)) {
        function handle(meta:MetadataEntry) {
          var options = parseOptions(meta.params, handler.options, meta.pos);
          handler.build(options, this, field);
          toRemove.push(meta);
        }

        switch field.meta.filter(match) {
          case [ m ]: handle(m);
          case many:
            Context.error('Only one @${handler.name} is allowed', many[1].pos);
        }
      }
    }

    if (toRemove.length > 0) for (entry in toRemove) {
      field.meta.remove(entry);
      // field.meta.push({ name: entry.name, pos: entry.pos });
    }
  }

  function parseClassMeta(classHandlers:Array<ClassMetaHandler<Dynamic>>) {
    if (cls.meta == null) return;
    
    var toRemove:Array<String> = [];

    for (handler in classHandlers) {
      if (cls.meta.has(handler.name)) {
        function handle(meta:MetadataEntry) {
          var options = parseOptions(meta.params, handler.options, meta.pos);
          handler.build(options, this, fields.copy());
          toRemove.push(handler.name);
        }
        switch cls.meta.extract(handler.name) {
          case [ m ]: handle(m);
          case many: Context.error('Only one @${handler.name} is allowed', many[1].pos);
        }
      }
    }

    if (toRemove.length > 0) for (name in toRemove) cls.meta.remove(name);
  }

  function parseOptions(
    params:Null<Array<Expr>>,
    def:Array<ClassBuilderOption>,
    pos:Position
  ):{} {
    var options:{} = {};

    if (params == null) return options;

    function addOption(name:String, value:Expr, pos:Position) {
      var info = def.find(o -> o.name == name);
      if (info == null) {
        Context.error('The option ${name} is not allowed here', pos);
      }
      if (Reflect.hasField(options, name)) {
        Context.error('The option ${name} was defined twice', pos);
      }
      Reflect.setField(options, name, info.handleValue != null
        ? info.handleValue(value)
        : parseConst(value)
      );
    }

    for (p in params) switch p {
      case macro ${ { expr:EConst(CIdent(s)), pos: _ } } = ${e}:
        addOption(s, e, p.pos);
      case macro ${ { expr:EConst(CIdent(s)), pos: _ } }:
        addOption(s, macro true, p.pos);
      default:
        Context.error('Invalid expression', p.pos);
    }

    for (o in def) {
      if (!Reflect.hasField(options, o.name)) {
        if (!o.optional) {
          Context.error('Missing required option ${o.name}', pos);
        }
      }
    }

    return options;
  }

  function parseConst(expr:Expr):Dynamic {
    return switch expr.expr {
      case EConst(c): switch c {
        case CIdent('false'): false;
        case CIdent('true'): true;
        case CString(s, _) | CIdent(s): s;
        case CInt(v): v;
        case CFloat(f): f;
        case CRegexp(_, _):
          Context.error('Regular expressions are not allowed here', expr.pos);
          null;
      }
      default: 
        Context.error('Values must be constant', expr.pos);
        null;
    }
  }
}
