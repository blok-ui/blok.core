package blok.parse;

import blok.parse.Attribute;
import blok.parse.Node;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.Tools;

typedef ParserOptions = {
  public final generateExpr:(nodes:Array<Node>)->Expr;
}

class Parser {
  final source:Source;
  final options:ParserOptions;

  var position:Int = 0;

  public function new(source, options) {
    this.source = source;
    this.options = options;
  }

  public function toExpr() {
    return options.generateExpr(parse());
  }

  public function parse():Array<Node> {
    position = 0;

    var nodes:Array<Node> = [];
    
    try while (!isAtEnd()) {
      whitespace();
      nodes.push(parseRoot());
    } catch (e:ParserException) {
      Context.error(e.message, e.pos);
    }
    
    return nodes;
  }

  function parseRoot() {
    whitespace();
    if (match('</')) errorAt(ParserException.unexpectedCloseTag, '</');
    if (match('<')) return parseNode();
    return parseExpr();
  }

  function parseNode():Node {
    var start = position - 1;

    whitespace();

    if (match('>')) return parseFragment();

    var tag = tag();
    var attributes:Array<Attribute> = [];
    var children:Array<Node> = [];

    whitespace();

    while (!checkAny('>', '/>') && !isAtEnd()) {
      whitespace();

      var name = identifier();
      
      if (name.value.length == 0) errorAt(ParserException.expectedIdentifier, peek());

      whitespace();

      var value:AttributeValue = if (match('=')) {
        whitespace();
        expression();
      } else ANone;

      whitespace();

      attributes.push({
        name: name,
        value: value
      });
    }

    whitespace();

    if (!match('/>')) {
      consume('>');
      children = parseChildren(switch tag {
        case TagBuiltin(name): name;
        case TagComponent(path): path.join('.');
        case TagAttribute(name): '.' + name;
      });
    }

    return {
      node: NNode(tag, attributes, children),
      pos: createPos(start, position)
    };
  }

  function parseChildren(closeTag:String):Array<Node> {
    var start = position;
    var children:Array<Node> = [];
    var didClose = false;

    function isClosed() {
      return didClose = attempt(() -> {
        if (match('</')) {
          whitespace();
          var tag = tag();
          return switch tag {
            case TagBuiltin(name): name == closeTag;
            case TagComponent(path): path.join('.') == closeTag;
            case TagAttribute(name): '.' + name == closeTag;
          }
        }
        return false;
      });
    }

    function closeTagError(start:Int) {
      whitespace();
      identifier();
      whitespace();
      match('>');
      error('Unclosed tag: ${closeTag}', start, position);
    }

    whitespace();
    try while (!isAtEnd() && !isClosed()) {
      var n = parseRoot();
      if (n != null) children.push(n);
      whitespace();
    } catch (e:ParserException) {
      if (e.message == ParserException.unexpectedCloseTag) {
        closeTagError(position - 2);
      } else throw e;
    }

    whitespace();
    consume('>');
    
    return children;
  }

  function parseExpr():Node {
    var expr = switch expression() {
      case AExpr(expr): expr;
      case ANone: macro null;
    }
    return {
      node: NExpr(expr),
      pos: expr.pos
    };
  }

  function parseFragment():Node{
    var start = position;
    var children = parseChildren('');
    return {
      node: NFragment(children),
      pos: createPos(start, position)
    }
  }
  function checkAttempt(handle:()->Bool) {
    var start = position;
    var res = attempt(handle);
    position = start;
    return res;
  }

  function attempt(handle:()->Bool) {
    var start = position;
    try {
      if (handle()) {
        return true;
      }
      position = start;
      return false;
    } catch (_:ParserException) {
      position = start;
      return false;
    }
  }

  function tag():NodeTag {
    if (match('.')) return TagAttribute(identifier().value);
    var parts = path();
    if (parts.length == 0) expected('Identifier');
    if (parts.length > 1 || isTypeIdentifier(parts[0].charAt(0))) return TagComponent(parts);
    return TagBuiltin(parts[0]);
  }

  function expression():AttributeValue {
    if (match('{')) {
      var exprStr = extractDelimitedString('{', '}');
      var expr = stringToExpression(exprStr);
      return AExpr(expr);
    }

    if (match('"')) {
      var str = extractDelimitedString('"', '"', true);
      return AExpr(macro @:pos(str.pos) $v{str.value});
    }

    if (match("'")) {
      var str = extractDelimitedString("'", "'", true);
      // Note: this is to allow for interpolation in single-quoted strings.
      var expr = stringToExpression(str);
      return AExpr(expr);
    }

    if (isIdentifier(peek())) {
      var located = identifier();
      return AExpr(macro @:pos(located.pos) $i{located.value});
    }

    return ANone;
  }

  function stringToExpression(exprStr:Located<String>):Expr {
    try return reenter(Context.parseInlineString(exprStr.value, exprStr.pos)) catch (e) {
      Context.error(e.message, exprStr.pos);
      return macro null;
    }
  }

  function reenter(e:Expr):Expr {
    return switch e {
      case macro @:markup ${{ expr: EConst(CString(_)) }}:
        new Parser(e, options).toExpr();
      default:
        e.map(reenter);
    }
  }
  
  function extractDelimitedString(startToken:String, endToken:String, escapable:Bool = false):Located<String> {
    var start = position;
    var depth = 1;

    while (!isAtEnd() && depth > 0) {
      if (escapable && (match('\\${startToken}') || match('\\${endToken}'))) {
        advance();
        continue;
      }
      
      if (check(endToken)) {
        depth--;
        if (depth == 0) break else {
          advance();
          continue;
        }
      }

      if (match(startToken)) {
        depth++;
        continue;
      }

      advance();
    }
    
    if (isAtEnd()) error('Unterminated value.', start, position);

    var value = source.content.substring(start, position);
    var pos = createPos(start, position - 1);

    consume(endToken);

    return {
      value: value,
      pos: pos
    };
  }

  function path() {
    return readWhile(() -> isAlphaNumeric(peek()) || checkAny('.', '-', '_')).split('.');
  }
  
  function identifier():Located<String> {
    var start = position;
    var value = readWhile(() -> isIdentifier(peek()));
    return {
      value: value,
      pos: createPos(start, position)
    };
  }

  function isIdentifier(s:String) {
    return isAlphaNumeric(s) || check('_');
  }

  function isTypeIdentifier(s:String) {
    return isUcAlpha(s);
  }
  
  function whitespace():Void {
    readWhile(() -> isWhitespace(peek()));
    // Comments
    if (match('//')) {
      readWhile(() -> peek() != '\n');
      return whitespace();
    }
    if (match('/*')) {
      extractDelimitedString('/*', '*/');
      return whitespace();
    }
  }
  
  function isWhitespace(c:String) {
    return c == ' ' || c == '\n' || c == '\r' || c == '\t';
  }

  function isDigit(c:String):Bool {
    return c >= '0' && c <= '9';
  }

  function isUcAlpha(c:String):Bool {
    return (c >= 'A' && c <= 'Z');
  }

  function isAlpha(c:String):Bool {
    return (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') ||
            c == '_';
  }

  function isAlphaNumeric(c:String) {
    return isAlpha(c) || isDigit(c);
  }

  function readWhile(compare:()->Bool):String {
    var out = [ while (!isAtEnd() && compare()) advance() ];
    return out.join('');
  }

  function ignore(...names:String) {
    for (name in names) match(name);
  }

  function match(value:String) {
    if (check(value)) {
      position = position + value.length;
      return true;
    }
    return false;
  }

  function matchAny(...values:String) {
    for (v in values) {
      if (match(v)) return true;
    }
    return false;
  }

  function check(value:String) {
    var found = source.content.substr(position, value.length);
    return found == value;
  }

  function checkAny(...values:String) {
    for (v in values) {
      if (check(v)) return true;
    }
    return false;
  }

  function checkAnyUnescaped(...items:String) {
    for (item in items) {
      if (check(item)) {
        if (previous() == '\\') return false;
        return true;
      }
    }
    return false;
  }

  function consume(value:String) {
    if (!match(value)) throw expected(value);
  }

  function peek() {
    return source.content.charAt(position);
  }

  function advance() {
    if (!isAtEnd()) position++;
    return previous();
  }

  function previous() {
    return source.content.charAt(position - 1);
  }

  function isAtEnd() {
    return position == source.content.length;
  }
  
  function error(msg:String, min:Int, max:Int) {
    throw new ParserException(msg, createPos(min, max));
  }

  function errorAt(msg:String, value:String) {
    return error(msg, position - value.length, position);
  }

  function reject(s:String) {
    return error('Unexpected [${s}]', position - s.length, position);
  }

  function expected(s:String) {
    return error('Expected [${s}]', position, position + 1);
  }

  function createPos(min:Int, max:Int) {
    return Context.makePosition({
      min: source.offset + min,
      max: source.offset + max,
      file: source.file
    });
  }
}
