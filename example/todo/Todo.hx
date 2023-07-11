package todo;

import Breeze;
import blok.context.*;
import blok.data.*;
import blok.html.*;
import blok.html.HtmlAttributes;
import blok.html.client.Client;
import blok.signal.*;
import blok.ui.*;
import haxe.Json;
import js.Browser;

using Reflect;
using breeze.BreezeModifiers;

function todos() {
  mount(
    Browser.document.getElementById('todo-root'),
    () -> TodoRoot.node({})
  );
}

enum abstract TodoVisibility(String) from String to String {
  var All;
  var Completed;
  var Active;
}

class Todo extends Record {
  @:constant public final id:Int;
  @:signal public final description:String;
  @:signal public final isCompleted:Bool;
  @:signal public final isEditing:Bool = false;
  
  public function toJson() {
    return {
      id: id,
      description: description(),
      isCompleted: isCompleted(),
      isEditing: isEditing()
    };
  }
}

@:fallback(TodoContext.load())
class TodoContext extends Record implements Context {
  static inline final storageId = 'pine-todo-store';

  public static function load():TodoContext {
    var data = js.Browser.window.localStorage.getItem(storageId);
    var context = if (data == null) {
      new TodoContext({uid: 0, todos: [], visibility: All});
    } else {
      fromJson(Json.parse(data));
    }

    Observer.track(() -> {
      js.Browser.window.localStorage.setItem(TodoContext.storageId, Json.stringify(context.toJson()));
    });

    return context;
  }
  
  public static function fromJson(data:Dynamic) {
    return new TodoContext({
      uid: data.field('uid'),
      todos: (data.field('todos'):Array<Dynamic>).map(data -> new Todo({
        id: data.id,
        description: data.description,
        isCompleted: data.isCompleted,
        isEditing: data.isEditing,
      })),
      visibility: data.field('visibility')
    });
  }

  @:signal public final uid:Int = 0;
  @:signal public final todos:Array<Todo>;
  @:signal public final visibility:TodoVisibility;
  @:computed public final total:Int = todos().length;
  @:computed public final completed:Int = {
    var todos = todos();
    todos.length - todos.filter(todo -> !todo.isCompleted()).length;
  }
  @:computed public final remaining:Int = {
    var todos = todos();
    todos.length - todos.filter(todo -> todo.isCompleted()).length;
  }
  @:computed public final visibleTodos:Array<Todo> = switch visibility() {
    case All: todos();
    case Completed: todos().filter(todo -> todo.isCompleted());
    case Active: todos().filter(todo -> !todo.isCompleted());
  }
  
  @:action
  public function addTodo(description:String) {
    uid.update(id -> id + 1);
    todos.update(todos -> [ new Todo({
      id: uid.peek(),
      description: description,
      isEditing: false,
      isCompleted: visibility.peek() == Completed
    }) ].concat(todos));
  }

  @:action
  public function removeTodo(todo:Todo) {
    todo.dispose();
    todos.update(todos -> todos.filter(t -> t != todo));
  }

  @:action
  public function removeCompletedTodos() {
    todos.update(todos -> todos.filter(todo -> {
      if (todo.isCompleted.peek()) {
        todo.dispose();
        return false;
      }
      return true;
    }));
  }

  public function toJson() {
    return {
      uid: uid(),
      todos: todos().map(todo -> todo.toJson()),
      visibility: visibility()
    };
  }
}

class TodoRoot extends StaticComponent {
  function render() {
    return TodoContext.provide(TodoContext.load, todos -> Fragment.node(
      TodoHeader.node({}),
      TodoList.node({}),
      TodoFooter.node({})
    ));
  }
}

class TodoHeader extends StaticComponent {
  function render():VNode {
    var todos = TodoContext.from(this);
    return Html.header({
      role: 'header'
    }).styles(
      Background.color('gray', 200),
      Spacing.pad(3)
    ).wrap(
      Html.h1({}).styles(
        Typography.fontSize('lg'),
        Typography.fontWeight('bold')
      ).wrap('Todos'),
      TodoInput.node({
        className: 'new-todo',
        value: '',
        clearOnComplete: true,
        onCancel: () -> null,
        onSubmit: description -> todos.addTodo(description)
      })
    );
  }
}

class TodoFooter extends StaticComponent {
  function render() {
    var todos = TodoContext.from(this);
    return Html.footer({
      style: todos.total.map(total -> if (total == 0) 'display: none' else null),
    }).styles(
      Background.color('black', 0),
      Typography.textColor('white', 0),
      Spacing.pad(3)
    ).wrap(
      Html.span({},
        Html.strong({}, todos.remaining.map(remaining -> switch remaining {
          case 1: '1 item left';
          default: '${remaining} items left';
        }))
      )
    ).into();
  }
}

class VisibilityControl extends StaticComponent {
  @:constant final visibility:TodoVisibility;
  @:constant final url:String;
  
  function render() {
    var todos = TodoContext.from(this);
    return Html.li({
      onClick: _ -> todos.visibility.set(visibility)
    }, Html.a({
        href: url,
        className: new Computation(() -> if (visibility == todos.visibility()) 'selected' else null),
      }, (visibility:String))
    ).into();
  }
}

class TodoInput extends ObserverComponent {
  @:constant final className:String;
  @:constant final clearOnComplete:Bool;
  @:constant final onSubmit:(data:String) -> Void;
  @:constant final onCancel:() -> Void;
  @:signal final value:String;
  @:observable final isEditing:Bool = false;

  function setup() {
    Observer.track(() -> {
      if (isEditing()) {
        (getRealNode():js.html.InputElement).focus();
      }
    });
  }

  function render():VNode {
    return Html.input({
      className: className,
      placeholder: 'What needs doing?',
      autofocus: true,
      value: value,
      onInput: e -> {
        var target:js.html.InputElement = cast e.target;
        value.set(target.value);
      },
      onBlur: _ -> {
        onCancel();
        if (clearOnComplete) {
          value.set('');
        }
      },
      onKeyDown: e -> {
        var ev:js.html.KeyboardEvent = cast e;
        if (ev.key == 'Enter') {
          onSubmit(value.peek());
          if (clearOnComplete) {
            value.set('');
          }
        } else if (ev.key == 'Escape') {
          onCancel();
          if (clearOnComplete) {
            value.set('');
          }
        }
      }
    });
  }
}

class TodoList extends StaticComponent {
  function render():VNode {
    var todos = TodoContext.from(this);
    return Html.section({
      className: 'main',
      ariaHidden: todos.total.map(total -> total == 0),
      style: todos.total.map(total -> total == 0 ? 'visibility:hidden' : null)
    }).wrap(
      Html.ul({}).styles(
        Flex.display(),
        Flex.gap(3),
        Flex.direction('column'),
        Spacing.pad(3)
      ).track(_ -> Fragment.node(...[ for (todo in todos.visibleTodos()) 
        TodoItem.node({ todo: todo }, todo.id)
      ]))
    );
  }
}

class TodoItem extends ObserverComponent {
  @:constant final todo:Todo;
  @:computed final className:String = [
    if (todo.isCompleted()) 'completed' else null,
    if (todo.isEditing()) 'editing' else null
  ].filter(c -> c != null).join(' ');

  function render():VNode {
    return Html.li({
      id: 'todo-${todo.id}',
      className: className
    }).styles(
      Flex.display(),
      Flex.gap(3)
    ).wrap(
      if (!todo.isEditing()) Fragment.node(
        Html.input({
          type: InputType.Checkbox,
          checked: todo.isCompleted,
          onClick: _ -> todo.isCompleted.update(status -> !status)
        }),
        Html.div({
          onDblClick: _ -> todo.isEditing.set(true),
          onClick: e -> {
            e.preventDefault();
            e.stopPropagation();
          }
        }, todo.description),
        Html.button({
          onClick: _ -> TodoContext.from(this).removeTodo(todo)
        }, 'Remove')
      ) else TodoInput.node({
        className: 'edit',
        isEditing: todo.isEditing,
        value: todo.description.peek(),
        clearOnComplete: false,
        onCancel: () -> todo.isEditing.set(false),
        onSubmit: data -> Action.run(() -> {
          todo.description.set(data);
          todo.isEditing.set(false);
        })
      })
    );
  }
}