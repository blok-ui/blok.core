package todo;

import Breeze;
import blok.context.*;
import blok.data.*;
import blok.html.*;
import blok.signal.*;
import blok.ui.*;
import haxe.Json;

using Kit;
using Reflect;

function todos() {
	Client.mount('#todo-root', TodoRoot.node({}));
}

enum abstract TodoVisibility(String) from String to String {
	var All;
	var Completed;
	var Active;
}

class Todo extends Model {
	@:value public final id:Int;
	@:signal public final description:String;
	@:signal public final isCompleted:Bool;
	@:signal public final isEditing:Bool = false;
}

@:fallback(TodoContext.load())
class TodoContext extends Model implements Context {
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

	public function addTodo(description:String) {
		uid.update(id -> id + 1);
		todos.update(todos -> [new Todo({
			id: uid.peek(),
			description: description,
			isEditing: false,
			isCompleted: visibility.peek() == Completed
		})].concat(todos));
	}

	public function removeTodo(todo:Todo) {
		todo.dispose();
		todos.update(todos -> todos.filter(t -> t != todo));
	}

	public function removeCompletedTodos() {
		todos.update(todos -> todos.filter(todo -> {
			if (todo.isCompleted.peek()) {
				todo.dispose();
				return false;
			}
			return true;
		}));
	}
}

class TodoRoot extends Component {
	function render() {
		return Html.view(<div className={Breeze.compose(
			Flex.display(),
			Flex.justify('center'),
			Spacing.pad(10),
		)}>
			<div className={Breeze.compose(
				Sizing.width('full'),
				Border.radius(2),
				Border.width(.5),
				Breakpoint.viewport('700px', Sizing.width('700px'))
			)}>
				<Provider context={TodoContext.load()}>
					<TodoHeader />
					<TodoList />
					<TodoFooter />
				</Provider>
			</div>
		</div>);
	}
}

class TodoHeader extends Component {
	@:context final todos:TodoContext;

	function render():VNode {
		return Html.view(<header role="header" className={Breeze.compose(
			Spacing.pad('x', 3)
		)}>
			<div className={Breeze.compose(
				Flex.display(),
				Flex.gap(3),
				Flex.alignItems('center'),
				Spacing.pad('y', 3),
				Border.width('bottom', .5)
			)}>
				<h1 className={Breeze.compose(
					Typography.fontSize('lg'),
					Typography.fontWeight('bold'),
					Spacing.margin('right', 'auto')
				)}>'Todos'</h1>
				<TodoInput 
					className = {Breeze.compose(
						'new-todo',
						Sizing.width('70%')
					)} 
					value = '' 
					clearOnComplete
					onCancel = {() -> null}
					onSubmit = {description -> todos.addTodo(description)}
				/>
			</div>
			<ul className={Breeze.compose(
				Flex.display(),
				Flex.gap(3),
				Spacing.pad('y', 3),
				Border.width('bottom', .5)
			)}>
				<VisibilityControl visibility=All />
				<VisibilityControl visibility=Active />
				<VisibilityControl visibility=Completed />
			</ul>
		</header>);
	}
}

class TodoFooter extends Component {
	@:context final todos:TodoContext;
	@:computed final display:String = switch todos.total() {
			case 0: 'display:none';
			default: '';
		}
	@:computed final message:String = switch todos.remaining() {
			case 1: '1 item left';
			case remaining: '${remaining} items left';
		}

	function render() {
		return Html.view(<footer
			className={Breeze.compose(
				Background.color('black', 0),
				Typography.textColor('white', 0),
				Spacing.pad(3)
			)}
			style=display
		>
			<span><strong>message</strong></span>
		</footer>);
	}
}

class VisibilityControl extends Component {
	@:context final todos:TodoContext;
	@:attribute final visibility:TodoVisibility;
	@:computed final isSelected:Bool = visibility == todos.visibility();

	function render() {
		return Html.view(<li>
			<Button
				action={() -> todos.visibility.set(visibility)}
				selected=isSelected
			>visibility</Button>
		</li>);
	}
}

class Button extends Component {
	@:attribute final action:() -> Void;
	@:children @:attribute final label:String;
	@:observable final selected:Bool = false;
	@:computed final className:ClassName = [
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
	];

	function render() {
		return Html.view(<button className=className onClick={_ -> action()}>label</button>);
	}
}

class TodoInput extends Component {
	@:attribute final className:String;
	@:attribute final clearOnComplete:Bool;
	@:attribute final onSubmit:(data:String) -> Void;
	@:attribute final onCancel:() -> Void;
	@:signal final value:String;
	@:observable final isEditing:Bool = false;

	@:effect function trackEditing():Void {
		if (isEditing()) {
			getPrimitive().as(js.html.InputElement)?.focus();
		}
	}

	function render():VNode {
		return Html.input({
			className: Breeze.compose(
				className,
				Spacing.pad('x', 3),
				Spacing.pad('y', 1),
				Border.radius(2),
				Border.color('black', 0),
				Border.width(.5)
			),
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

class TodoList extends Component {
	@:context final todos:TodoContext;
	@:computed final visibleTodos:Array<Todo> = todos.visibleTodos();
	@:computed final hidden:Bool = todos.total() == 0;
	@:computed final style:Null<String> = hidden() ? 'visibility:hidden' : null;

	function render():VNode {
		return Html.view(<section 
			className="main"
			ariaHidden=hidden
			style=style
		>
			<ul className={Breeze.compose(
				Flex.display(),
				Flex.gap(3),
				Flex.direction('column'),
				Spacing.pad(3)
			)}>
				<Scope>
					{_ -> <>
						{for (todo in visibleTodos()) <TodoItem todo=todo key={todo.id} />}
					</>}
				</Scope>
			</ul>
		</section>);
	}
}

class TodoItem extends Component {
	@:context final todos:TodoContext;
	@:attribute final todo:Todo;
	@:computed final className:ClassName = [
		if (todo.isCompleted() && !todo.isEditing()) Typography.textColor('gray', 500) else null,
		Flex.display(),
		Flex.gap(3),
		Flex.alignItems('center'),
		Spacing.pad('y', 3),
		Border.width('bottom', .5),
		Border.color('gray', 300),
		Select.child('last', Border.style('bottom', 'none'))
	];

	function render():VNode {
		return Html.view(<li id={'todo-${todo.id}'} className={className} onDblClick={_ -> todo.isEditing.set(true)}>
			{if (!todo.isEditing()) <>
				<input 
					type={blok.html.HtmlAttributes.InputType.Checkbox}
					checked={todo.isCompleted}
					onClick={_ -> todo.isCompleted.update(status -> !status)}
				/>
				<div className={Spacing.margin('right', 'auto')}>{todo.description}</div>
				<Button action={() -> todo.isEditing.set(true)}>'Edit'</Button>
				<Button action={() -> todos.removeTodo(todo)}>'Remove'</Button>
			</> else TodoInput.node({
				className: Breeze.compose(
					'edit',
					Sizing.width('full')
				),
				isEditing: todo.isEditing,
				value: todo.description.peek(),
				clearOnComplete: false,
				onCancel: () -> todo.isEditing.set(false),
				onSubmit: data -> {
					todo.description.set(data);
					todo.isEditing.set(false);
				}
				// onSubmit: data -> Action.run(() -> {
				//   todo.description.set(data);
				//   todo.isEditing.set(false);
				// })
			})}
		</li>);
	}
}
