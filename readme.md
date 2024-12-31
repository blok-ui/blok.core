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

> Note: this section is a work in progress.

Blok is a *reactive framework*. When a value changes, it automatically tracks it and updates as needed.

The core mechanism to make this possible are *Signals*. Blok's implementation is based heavily on [Preact's Signals](https://github.com/preactjs/signals) and (especially) on the implementation used by [Angular](https://github.com/angular/angular/blob/4be253483d045cfee6b42766c9dfd8c9888057e0/packages/core/primitives/signals).

Generally you won't be creating Signals directly (we'll get into why in the Components and Models sections below), but it's useful to understand what's going on with them. Lets set up a simple example:

```haxe
var foo = new blok.signal.Signal('Foo');
```

> Note: `blok.signal.Signal` is an abstract, so the above could also be written `var foo:blok.signal.Signal<String> = 'foo'`. This is a handy Haxe feature that Blok makes extensive use of to make authoring VNodes more ergonomic.

Reading and writing the value of `foo` can be done as follows:

```haxe
// Call it like a function (recommended):
trace(foo());
// Or use the getter:
trace(foo.get());

// Use `set` to update the value:
foo.set('bar');
// ...or `update` to also get access to the current value:
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

If you run this code, you'll notice something: it traces "foo", "foobar" and finally "done". This is the key to the power of signals: by simply by calling `foo()` inside our `Observer` we've subscribed to it and will re-run every time `foo` changes.

> Note: if you want to get the value of a Signal *without* subscribing to it, you can use the `peek` method (e.g. `foo.peek()`).

Note that when signals change their Observers will update *asynchronously* since Blok uses a scheduling mechanism behind the scenes. This is to ensure that other asynchronous events, like HTTP requests, don't update out of order and potentially cause strange behavior.

> Todo: Explain `Computation`, especially the fact that it *can* update synchronously when it's accessed.

## Components

> Note: this section is a work in progress.

Blok apps are built out of Components, and they're the primary thing you'll be using. Let's bring back our Counter example:

> Note: Blok *does* have a JSX-like DSL, but it's still very experimental so we're going to be sticking to a alternate, fluent API to create elements. You can use either method in your apps.

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

> Note: this is still very much in progress and these descriptions are probably not very helpful yet.

### @:attribute

Attributes are (mostly) immutable properties passed into a component. In 90% of cases, an `:attribute` is all you want to use.

> Implementation Details: Under the hood attributes are actually ReadOnlySignals, but are designed to only be updated externally when a Component's VNode is changed. Because all Component render methods are wrapped in a Computation this is a simple way to ensure that Components only update when their dependencies change.
>
> Additionally, this ensures that attributes work correctly with *any* Observers, including `:resource` and `:effect`, all for free.

### @:signal

Signal fields create readable/writeable Signals (see the [previous section](#signals)). 

Conceptually, this is somewhat similar to `useState` in React, and should be used sparingly. `:signal` fields are there when you have some simple state that a Component needs to use internally (like, for example, updating a counter or -- more realistically -- toggling the visibility of a modal).

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

While you might be tempted to create Computations inside a render method, resist this impulse. Computations must be tracked, and every time a render method is re-run any tracked computation (or Observable) will be disposed. It's much more efficient to keep all your computations outside the render method and on your Component where they will only be created once.

```haxe
@:signal final foo:String;
@:computed final fooBar:String = foo() + ' bar';
```

### @:resource

Resource fields allow you to use async values (such as HTTP requests) in conjunction with [SuspenseBoundaries](#suspense-boundaries-and-resources). This is a complex topic that involves several overlapping Blok features, so see the [Resources](#resources) section for more.

### @:effect

Effect methods allow you to create Observers that track reactive Signals. The marked method will simply be run every time one of its dependencies changes, potentially running a cleanup function whenever this happens.

```haxe
// Like this method from our example
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

Marks field as the slot to use for children in a markup node. This is only relevant if you're using the markup feature (such as inside `Html.view(...)`). Note that this can't be used on it's own and that it has to be attached to a field that will also be present in the Component's constructor (typically an `:attribute`).

```haxe
class Example extends Component {
  @:children @:attribute final children:Children;

  // etc
}
```

A component may only have one `:children` field. While this field is typically a `Child` or `Children`, it does not have to be, and this can open up some additional options. For example, the `blok.Show` component expects a method (`() -> Child`) for its `:children` attribute:

```haxe
Html.view(<Show condition=someSignal>
  {() -> <p>'Hi world'</p>}
</Show>);
```

If you're not using markup you can ignore this, but if you're making a library intended for others you should be sure to include it.

### Setup

In addition to all the above features, Components also have a `setup` method you can implement if you need to. `setup` will be run once, **after** the Component has been mounted. This is a great place to initialize some external dependency, do something complex with the real DOM (using `getPrimitive`) or to enqueue some cleanup functions (via `addDisposable`).

> Todo: More on all that soon!

## Models and Objects

> Note: this section is coming soon.

## Suspense Boundaries and Resources

> Note: This section will be expanded and improved soon.

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
