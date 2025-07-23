# Blok Core

Blok is a reactive UI framework built for the web but flexible enough to be used elsewhere.

## Getting Started

Blok is not yet on haxelib, but you can install it using [Lix](https://github.com/lix-pm/lix.client).

```
lix install gh:blok-ui/blok
```

To get a sense of how Blok works, try creating a simple counter app:

```haxe
import blok.*;
import blok.html.*;

function main() {
  Client.mount('#root', Counter.node({}));
}

class Counter extends Component {
  @:signal final count:Int = 0;

  function decrement(_:blok.html.HtmlEvents.Event) {
    count.update(count -> count > 0 ? count - 1 : 0);
  }

  function render() return Html.view(<div>
    <div>count</div>
    <button onClick=decrement>"-"</button>
    <button onClick={ _ -> count.update(count -> count + 1)}>"+"</button>
  </div>);
}
```

## Signals

Blok is a *reactive framework*. When a value changes, it automatically tracks it and updates as needed.

The core mechanism to make this possible are *Signals*. Blok's implementation is based heavily on [Preact's Signals](https://github.com/preactjs/signals) and (especially) on the implementation used by [Angular](https://github.com/angular/angular/blob/4be253483d045cfee6b42766c9dfd8c9888057e0/packages/core/primitives/signals).

Generally you won't be creating Signals directly (we'll get into why in the Components and Models sections below), but it's useful to understand what's going on with them. Lets set up a simple example:

```haxe
var foo = new blok.signal.Signal('Foo');
```
Here's a quick overview of the Signal API:

```haxe
// To get a value, you can call it like a function (recommended):
trace(foo());
// ...or use the `get` method:
trace(foo.get());

// Use `set` to update the value:
foo.set('bar');
// ...or use `update` if you need access to the current value:
foo.update(value -> 'foo' + value);
```

None of this is particularly interesting on its own, but it becomes much more useful when we pair our Signal with an Observer:

```haxe
import blok.signal.*;

function main() {
  var foo:Signal<String> = 'foo';
  Observer.track(() -> {
    trace(foo());
  });

  foo.update(value -> value + 'bar');
  foo.set('done');
}
```

If you run this code, you'll notice that it traces "foo", "foobar" and finally "done". By simply calling `foo()` inside our observer we've subscribed to it and the observer will re-run every time the `foo` signal changes.

> Note: if you want to get the value of a Signal *without* subscribing to it, you can use the `peek` method (e.g. `foo.peek()`).

When signals change their observers will update *asynchronously* since Blok uses a scheduling mechanism behind the scenes. This is to ensure that other asynchronous events, like HTTP requests, don't update out of order and potentially cause strange behavior and that multiple signal changes happening at once don't trigger more than one update.

## Computations

If you need to change the value of a signal while keeping it reactive, you can use the `map` method:

```haxe
var continue:Signal<Bool> = false;
var stop:Computation<Bool> = signal.map(status -> !status);
```

Under the hood this uses a `blok.signal.Computation`, a class that works a bit like an observer that returns a value. 

For example:

```haxe
var a = new Signal(1);
var b = new Signal(2);
var sum = new Computation(() -> a() + b());

Observer.track(() -> trace(sum()));
// will trace 3
a.set(2);
// will trace 4
```

Unlike Observers, Computations keep track of their producers and consumers. Should a Computation ever reach a state where it no longer has any consumers, it will stop being live and will remove itself from the reactive graph, freeing itself up to be garbage collected. This means you don't need to worry about manually disposing Computations. This is not always desirable (as you will often want a Computation to stay live even if it doesn't have any consumers), in which case you can use the `Computation.persist(...)` static method. Note that Computations created this way *must* be manually disposed *and* will not be observable themselves.

```haxe
var a = new Signal(1);
var b = new Signal(2);
var sum = new Computation(() -> a() + b());

// We're calling this outside an Observer, which means `sum` has no consumers. As a result
// it will be computed once and then disconnected.
trace(sum()); // -> 3
a.set(2);
// `sum` is no longer live, which means it has been removed from the reactive graph. As a result,
// the value has not been changed.
trace(sum()); // -> 3

var sum2 = Computation.persist(() -> a() + b());

trace(sum2()); // -> 4
a.set(3);
// Because we're using an persistent Computation it is always live and thus
// does change when our signals do:
trace(sum2()); // -> 5

// Remember to dispose persistent computations yourself, if you're not in a context where this
// is handled!
sum2.dispose();
```

Another important detail is that Computations are not always async -- they can also be validated on-demand, checking their producers for their most up-to-date values whenever they are called.

## Ownership

Lets talk a little more about disposing things, and why you typically won't need to do this yourself.

A great many classes in Blok implement `blok.Disposable`, a simple interface that exposes a `dispose` method. The most common cases you'll come across are `blok.signal.Observable` and the persistent version of `blok.signal.Computation`. These examples can be disposed manually, but they also automatically add themselves to the current Ownership context, if one exists.

To explain this, let's look at the `blok.Owner` class;

```haxe
var owner = new blok.Owner();

// `capture` is a macro that sets the current Owner, runs a block of code, and then resets
// the Owner to the previous Owner instance, if any.
Owner.capture(owner, {
  Owner.current() == owner; // -> true
  Owner.current().addDisposable(() -> trace('foo'));
});

owner.dispose(); // Will trace "foo"
```

Observers and persistent Computations will add themselves to `Owner.current()`, if it's set, meaning that instead of having to keep track of a bunch of disposables you can just do this:

```haxe
var owner = new Owner();
var a = new Signal(1);
var b = new Signal(2);
var sum = new Computation(() -> a() + b());

Owner.capture(owner, {
  Observer.track(() -> trace(sum()));
});

a.set(2);
// will trace 4

owner.dispose();

a.set(3);
// Nothing is traced -- the Observer was disposed.
```

You typically won't need to set this up yourself, but this is the mechanism being used behind the scenes to keep things tidy. Methods like `Component.setup`, `Component.render` are run in Ownership contexts, so you can safely use Observers and persistent Computations there. If you're unsure if a method is in an ownership context you can call `Owner.isInOwnershipContext()` to check.

If you want to dispose a class when the current owner is disposed, you can do the following:

```haxe
class Example implements Disposable {
  public function new() {
    Owner.current()?.addDisposable(this);
  }

  public function dispose() {
    trace('Disposed');
  }
}
```

## Components

Now that we have a handle on how Blok handles reactivity it's time to actually create a UI. Blok apps are primarily built out of Components, so let's bring back our Counter example (with a few more things added) and start to dig into it:

```haxe
import blok.*;
import blok.html.*;

function main() {
  // Note that you can pass an element to `mount` instead of a query selector
  // if you prefer.
  var root = js.Browser.document.getElementById('root');
  Client.mount(root, Counter.node({}));
}

class Counter extends Component {
  @:attribute final increment:Int = 1;
  @:signal final count:Int = 0;
  @:computed final className = 'counter-${count()}';

  @:effect function traceWhenCountChanges() {
    trace('Count is currently ${count()}');
    return () -> trace(
      'This is a clean-up function, run when '
      + 'the Component is disposed or the effect ' 
      + 'is re-computed.'
    );
  }

  function decrement(_:blok.html.HtmlEvents.Event) {
    count.update(count -> count > 0 ? count - increment : 0);
  }

  function render():Child {
    // Blok *does* have a JSX-like DSL, but it's still very experimental. We're going 
    // to stick to a alternate, fluent API in these examples. You can use either 
    // approach in your apps.
    return Html.div()
      .attr(ClassName, className)
      .child([
        Html.div().child(count),
        Html.button().on(Click, decrement).child('-'),
        Html.button()
          .on(Click, _ -> count.update(count -> count + increment)) 
          .child('+')
      ]);
  }
}
```

In our `Counter` class, you'll note that we have a bunch of class fields marked with metadata. These are fairly self-explanatory, but let's go over them one by one.

### @:attribute

Attributes are (mostly) immutable properties passed into a component. In 90% of cases, an `:attribute` is all you want to use.

> Implementation Details: Under the hood attributes are actually ReadOnlySignals, but are designed to only be updated externally when a Component's VNode is changed. Because all Component render methods are wrapped in a Computation this is a simple way to ensure that Components only update when their dependencies change.
>
> Additionally, this ensures that attributes work correctly with *any* Observers, including `:resource` and `:effect`, all for free.

### @:signal

Signal fields create readable/writeable Signals (see the [previous section](#signals)). 

Conceptually, this is somewhat similar to `useState` in React. `:signal` fields are there when you have some state that a Component needs to use internally (like, for example, updating a counter or -- more realistically -- toggling the visibility of a modal or other element).

### @:observable

Observable fields are read-only Signals passed in from some outside source (such as a parent component).

This is roughly the same as creating an attribute wrapping a ReadOnlySignal, but is more convenient. Use it when you want to explicitly use a signal from an outside source.

```haxe
// The following are roughly equivalent:
@:observable final foo:String;
@:attribute final foo:blok.signal.Signal.ReadOnlySignal<String>;
```

### @:computed

Computed fields allow you to derive reactive values from any number of Signals.

```haxe
@:signal final foo:String;
@:computed final fooBar:String = foo() + ' bar';
```

### @:resource

Resource fields allow you to use async values (such as HTTP requests) in conjunction with [SuspenseBoundaries](#suspense-boundaries-and-resources). This is a complex topic that involves several overlapping Blok features, so see the [Resources](#resources) section for more.

### @:effect

Effect methods allow you to create Observers that track reactive Signals. The marked method will simply be run every time one of its dependencies changes, potentially running a cleanup function whenever this happens.

```haxe
@:effect function traceWhenCountChanges() {
  trace('Count is currently ${count()}');
  return () -> trace(
    'This is a clean-up function, run when '
    + 'the Component is disposed or the effect ' 
    + 'is re-computed.'
  );
}
```

Note that if you *don't* want a cleanup function you must explicitly mark the return type as `Void`.

```haxe
@:effect function traceWhenCountChanges():Void {
  trace('Count is currently ${count()}');
}
```

Effects can also accept a few arguments so long as they are marked with a small selection of metadata. Right now, the only available option is `@:primitive` (which will inject the component's current primitive). Other arguments might be added later.

```haxe
@:effect function traceCurrentPrimitive(@:primitive el:js.html.Element):Void {
  trace(el);
}
```

### @:context

Use the given [Context](#providing-context). This is a convenience method that is roughly equivalent to calling `SomeContext.from(this)` but which can make your code look a little neater.

```haxe
@:context final users:SomeUserContext;
@:attribute final id:String;
@:resource final user:User = users.fetch(id);
// Roughly the same as doing:
@:resource final user:User = SomeUserContext.from(this).fetch(id);
```

### @:children

Marks field as the slot to use for children in a markup node. This is only relevant if you're using the markup feature (such as inside `Html.view(...)`). Note that this can't be used on its own and that it has to be attached to a field that will also be present in the Component's constructor (typically an `:attribute`).

```haxe
class Example extends Component {
  @:children @:attribute final children:Children;

  // etc
}
```

A component may only have one `:children` field. While this field is typically a `blok.Child` or `blok.Children`, it does not have to be. For example, the `blok.Show` component expects a method (`() -> Child`) for its `:children` attribute:

```haxe
Html.view(<Show condition=someSignal>
  {() -> <p>'Hi world'</p>}
</Show>);
```

If you're not using markup you can ignore this, but if you're making a library intended for others you should be sure to include it.

### Setup

In addition to all the above features, Components also have a `setup` method you can implement if you need to. `setup` will be run once, **after** the Component has been mounted. This is a great place to initialize some external dependency, do something complex with the DOM, or to enqueue some cleanup functions (via `addDisposable`). Setup is also run in an ownership context, so you can safely create `Observables` and similar objects there.

### Investigating Components

Occasionally you'll need to do something complex that Blok's declarative model can't handle. For these scenarios you can use the `investigate` method, although you should use this sparingly.

```haxe
var investigator = investigate();

// Blok is agnostic about what it's actually rendering, so it refers to the DOM nodes / objects / strings
// or whatever as "Primitives". Here's how you get at it:
var primitive = investigator.getPrimitive();

// Note that `primitive` is typed as `Any`, so you'll need to manually figure out what it is. To help with
// this, you can get the Root view and check what Adaptor it's using:
switch Root.from(this).adaptor.environment.name {
  case 'html/client':
    trace(primitive is js.html.Node); // true
  case 'html/server':
    trace(primitive is blok.html.server.NodePrimitive); // true
  default: 
    trace('unknown');
}
```

> Todo: More examples to come.

## Models and Objects

Models and objects are simple ways to, well, model data. Models have reactive data, while Objects do not.

Models use most of the same metadata as Components, although they use `:value` instead of `:attribute`. `:value` properties are truly immutable, and do not wrap a `ReadOnlySignal` like `:attribute`s do.

```haxe
class Todo extends blok.data.Model {
  @:value public final id:Int;
  @:signal public final content:String;
  @:signal public final active:Bool = false;
  @:computed public final activeLabel:String = if (active()) 'Active' else 'Inactive';
}
```

Objects are not reactive, and can only use `:value` fields and a `:prop` field:

```haxe
class Name extends blok.data.Object {
  @:value public final firstName:String;
  @:value public final lastName:String;
  // Note: You can also define `set` using @:prop, should you wish to. This is just
  // a convenience wrapper around Haxe's annoying property syntax.
  @:prop(get = firstName + ' ' + lastName) public final fullName:String;
}
```

Models and Objects use a build macro similar to the one Components use, and will automatically create a constructor for you:

```haxe
function main() {
  var todo = new Todo({
    id: 1,
    content: 'foo',
    active: false
  });
  var name = new Name({
    firstName: 'Guy',
    lastName: 'Manlike' 
  });
}
```

If you need to run some code when a Model or Object is constructed you can define a `new` method, however you cannot use any arguments with it. This code will be placed at the end of the constructor Blok generates, after all fields have been initialized.

```haxe
class Name extends blok.data.Object {
  @:value public final firstName:String;
  @:value public final lastName:String;
  @:prop(get = firstName + ' ' + lastName) public final fullName:String;

  function new() {
    trace(fullName);
  }
}
```

Both Models and Objects have a `Serializable` variant which allow them to be converted to/from JSON, should that be something you need. This will check that all properties are also serializable (meaning that they are either scalar values, like Strings, Bools, Ints, etc) or also implement a `fromJson` static method and a `toJson` method. If needed, you can use the `:json` meta to provide your own serializer.

```haxe
class Todo extends blok.data.SerializableModel {
  // This is a silly example, but if you -- for some reason -- needed to serialize the id
  // field as a string this is how you would do it:
  @:json(from = Std.parseInt(value), to = Std.string(value))
  @:value public final id:Int;
  @:signal public final content:String;
  @:signal public final active:Bool = false;
  @:computed public final activeLabel:String = if (active()) 'Active' else 'Inactive';
}

function main() {
  var todo = Todo.fromJson({
    id: "1",
    content: "bar",
    active: false
  });

  trace(todo);
  trace(todo.toJson());
}
```

## Suspense Boundaries and Resources

When dealing with asynchronous code you'll want to use Blok's Suspense apis.

### Resources

First, you'll need to set up a Resource. A resource is a reactive object (a bit like a Computation) that resolves some async Task. Here's a simple example:

```haxe
final resource = new blok.signal.Resource<String>(() -> {
  new kit.Task(activate -> haxe.Timer.delay(() -> activate(Ok('loaded')), 1000));
});
```

As previously mentioned, Resources are reactive, so we can cause our Resource to recompute if we use a Signal:

```haxe
final delay:Signal<Int> = 1000;
final resource = new blok.signal.Resource<String>(() -> {
  // Note that we have to use our Signal here for the Resource to capture it:
  var time = delay(); 
  new kit.Task(activate -> haxe.Timer.delay(() -> activate(Ok('loaded')), time));
});
```

As with other features in Blok, you'll almost never need to create a resource this way. Instead, you'll be using `@:resource` fields on components:

```haxe
class TimerExample extends Component {
  @:resource final timer:String = new kit.Task(activate -> {
    haxe.Timer.delay(() -> activate(Ok('loaded')), 1000);
  });

  function render():Child {
    return Html.p().child(timer());
  }
}
```

### SuspenseBoundaries

If you try to use the component created above, you'll get an uncaught `SuspenseException` and your app will break. To fix this, we need to add a SuspenseBoundary.

```haxe
class TimerWrapper extends Component {
  function render():Child {
    return blok.SuspenseBoundary.node({
      onComplete: () -> trace('Done!'),
      onSuspended: () -> trace('Suspending!'),
      children: TimerExample.node({}),
      fallback: () -> Html.p().child('Suspended...')
    });
  }
}
```

Now instead of breaking the component will display `<p>Suspended...</p>` until the `TimerExample`'s resource is activated.

### SuspenseBoundaryContext

SuspenseBoundaries do *not* propagate suspensions upwards (unless you set their `overridable` properties to `true`, in which case they will defer suspension to their closest ancestor, if any). If you want to take some action when multiple suspensions occur, you can use a `SuspenseBoundaryContext`.

```haxe
class TimerApp extends Component {
  function render():Child {
    return blok.Provider
      .provide(new blok.SuspenseBoundaryContext({
        onComplete: () -> trace('All suspensions complete')
      }))
      .child(_ -> Fragment.of([
        TimeWrapper.node({}),
        TimeWrapper.node({})
      ]));
  }
}
```

## Providing Context

> Note: This section is a work in progress

There are many cases where you might need to share information between Components. You could just pass a context object down as an attribute through every Component until you get it to the one you want, but UI frameworks have long ago come up with a much better solution.

### Context

The first thing we need to do is create a class that implements `blok.Context`.

```haxe
import blok.Context;

@:fallback(new ValueContext('default'))
class ValueContext implements Context {
  public final value:String;

  public function new(value) {
    this.value = value;
  }

  public function dispose() {}
}
```

Note the `@:fallback` metadata. This is required for all Contexts and will be used if a Context cannot be resolved. You can also throw an exception here instead if you want to force the user to provide a Context.

> Todo: describe how Contexts get disposed, especially how fallback values will be disposed along with the view that requested them.

### Provider

> Coming soon
