package todo;

import Breeze;
import blok.context.*;
import blok.data.*;
import blok.html.*;
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

@:fallback(TodoContext.instance())
class TodoContext extends Record implements Context {
  static public function instance() {
    static var context:Null<TodoContext> = null;
    if (context == null) {
      context = TodoContext.load();
    }
    return context;
  }

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

class TodoRoot extends Component {
  function render() {
    return Html.div({},
      Html.div({}, TodoContext.provide(TodoContext.instance, todos -> Fragment.node(
        TodoHeader.node({}),
        TodoList.node({}),
        TodoFooter.node({})
      ))).styles(
        Sizing.width('full'),
        Border.radius(2),
        Border.width(.5),
        Breakpoint.viewport('700px', Sizing.width('700px'))
      )  
    ).styles(
      Flex.display(),
      Flex.justify('center'),
      Spacing.pad(10),
    );
  }
}

class TodoHeader extends Component {
  function render():VNode {
    var todos = TodoContext.from(this);
    return Html.header({
      role: 'header'
    }, 
      Html.div({},
        Html.h1({}, 'Todos').styles(
          Typography.fontSize('lg'),
          Typography.fontWeight('bold'),
          Spacing.margin('right', 'auto')
        ),
        TodoInput.node({
          className: 'new-todo',
          value: '',
          clearOnComplete: true,
          onCancel: () -> null,
          onSubmit: description -> todos.addTodo(description)
        }).styles(
          Sizing.width('70%')
        )
      ).styles(
        Flex.display(),
        Flex.gap(3),
        Flex.alignItems('center'),
        Spacing.pad('y', 3),
        Border.width('bottom', .5)
      ),
      Html.ul({}, 
        VisibilityControl.node({ visibility: All }),
        VisibilityControl.node({ visibility: Active }),
        VisibilityControl.node({ visibility: Completed }),
      ).styles(
        Flex.display(),
        Flex.gap(3),
        Spacing.pad('y', 3),
        Border.width('bottom', .5)
      )
    ).styles(
      Spacing.pad('x', 3)
    );
  }
}

class TodoFooter extends Component {
  function render() {
    var todos = TodoContext.from(this);
    return Html.footer({
      style: todos.total.map(total -> if (total == 0) 'display: none' else null),
    },
      Html.span({},
        Html.strong({}, todos.remaining.map(remaining -> switch remaining {
          case 1: '1 item left';
          default: '${remaining} items left';
        }))
      )
    ).styles(
      Background.color('black', 0),
      Typography.textColor('white', 0),
      Spacing.pad(3)
    );
  }
}

class VisibilityControl extends Component {
  @:constant final visibility:TodoVisibility;
  
  function render() {
    var todos = TodoContext.from(this);
    return Html.li({},
      Button.node({
        action: () -> todos.visibility.set(visibility),
        selected: new Computation(() -> visibility == todos.visibility()),
        label: visibility
      }) 
    );
  }
}

class Button extends Component {
  @:constant final label:String;
  @:constant final action:()->Void;
  @:observable final selected:Bool = false;

  function render() {
    return Html.button({
      onClick: _ -> action()
    }, label).observedStyles(new Computation<ClassName>(() -> [
      Spacing.pad('x', 3),
      Spacing.pad('y', 1),
      Border.radius(2),
      Border.width(.5),
      Border.color('black', 0),
      if (selected()) Breeze.compose(
        Background.color('black', 0),
        Typography.textColor('white', 0)
      ) else Breeze.compose(
        Background.color('white', 0),
        Typography.textColor('black', 0),
        Modifier.hover(
          Background.color('gray', 200)
        )
      )
    ]));
  }
}

class TodoInput extends Component {
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
    }).styles(
      Spacing.pad('x', 3),
      Spacing.pad('y', 1),
      Border.radius(2),
      Border.color('black', 0),
      Border.width(.5)
    );
  }
}

class TodoList extends Component {
  function render():VNode {
    var todos = TodoContext.from(this);
    return Html.section({
      className: 'main',
      ariaHidden: todos.total.map(total -> total == 0),
      style: todos.total.map(total -> total == 0 ? 'visibility:hidden' : null)
    },
      Html.ul({}, Scope.wrap(_ -> Fragment.node(...[ for (todo in todos.visibleTodos()) 
        TodoItem.node({ todo: todo }, todo.id)
      ]))).styles(
        Flex.display(),
        Flex.gap(3),
        Flex.direction('column'),
        Spacing.pad(3)
      )
    );
  }
}

class TodoItem extends Component {
  @:constant final todo:Todo;
  @:computed final className:ClassName = [
    if (todo.isCompleted() && !todo.isEditing()) Typography.textColor('gray', 500) else null,
    // if (todo.isEditing()) 'editing' else null
  ];

  function render():VNode {
    return Html.li({
      id: 'todo-${todo.id}',
      className: className,
      onDblClick: _ -> todo.isEditing.set(true),
    },
      if (!todo.isEditing()) Fragment.node(
        Html.input({
          type: blok.html.HtmlAttributes.InputType.Checkbox,
          checked: todo.isCompleted,
          onClick: _ -> todo.isCompleted.update(status -> !status)
        }),
        Html.div({}, todo.description).styles(Spacing.margin('right', 'auto')),
        Button.node({
          action: () -> todo.isEditing.set(true),
          label: 'Edit'
        }),
        Button.node({
          action: () -> TodoContext.from(this).removeTodo(todo),
          label: 'Remove'
        })
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
      }).styles(Sizing.width('full'))
    ).styles(
      Flex.display(),
      Flex.gap(3),
      Flex.alignItems('center'),
      Spacing.pad('y', 3),
      Border.width('bottom', .5),
      Border.color('gray', 300),
      Select.child('last', Border.style('bottom', 'none'))
    );
  }
}
