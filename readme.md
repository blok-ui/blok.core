# Blok Core

Blok is a reactive UI framework built for the web but flexible enough to be used elsewhere.

## Getting Started

Blok is not yet on haxelib, but you can install it using [Lix](https://github.com/lix-pm/lix.client).

```
lix install gh:blok-ui/blok.core
```

To get a sense of how Blok works, try creating a simple counter app:

```haxe
import blok.ui.*;
import blok.html.Html;

function main() {
  Client.mount(
    js.Browser.document.getElementById('root'),
    () -> Counter.node({})
  )
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
import blok.ui.*;
import blok.html.*;

function main() {
  Client.mount(
    js.Browser.document.getElementById('root'),
    () -> Counter.node({})
  )
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

Attributes are (mostly) immutable properties passed into a component.  

### @:signal

Signal fields create readable/writeable Signals (see the previous section). This is somewhat similar to `useState` in React.

### @:observable

Observable fields are read-only Signals passed in from some outside source (such as a parent component).

### @:computed

Computed fields allow you to derive reactive values from any number of Signals.

### @:resource

Resource fields allow you to use async values (such as HTTP requests) in conjunction with [SuspenseBoundaries](#suspense-boundaries-and-resources). 

### @:effect

Effect methods allow you to create reactive side-effects that track reactive Signals.

### @:context

Use the given Context.

## Models

> Note: this section is coming soon.

## Suspense Boundaries and Resources

> Note: this section is coming soon.

## Context

> Note: this section is coming soon.
