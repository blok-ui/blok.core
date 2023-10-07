Here's the top-level idea:

```haxe
class Foo extends Component {
  @:constant final label:String;
  // New meta for Components: `@:child` or `@:children`, which
  // will capture unwrapped child nodes. Only one is allowed per
  // component.
  @:children final children:Children;

  function render() {
    // Every target has its own `view` macro that handles
    // non-component tags (like `div`) correctly.
    return blok.html.View.view(<div class="foo">
      <.onClick>
        // Attributes can be set like this if desired.
        {e -> trace('yay')}
      </.onClick>
      <Bar label={label}>
        // We should come up with a mechanism to allow automatic children
        // (probably just an `@:children` meta on an attribute), but
        // we can also allow 'slots' like this:
        <.children>
          "Child strings need to be wrapped in quotes?"
          "This will allow us to just throw an identifier in like this:"
          label
          "...although more complex stuff will need to be wrapped in brackets."
          children // Children should be automatically applied.
        </.children>
      </Bar>
      // Reentrance allows us to just use haxe conditionals:
      {if (true) <span>"Yay"</span> else <span>"Nope"</span>}
      // Or something like this, which is just a normal Component
      // named `If`:
      <If value={true}>
        <.then>"Yay"</.then>
        <.otherwise>"Nay"</.otherwise>
      </Show>
      // For things like context:
      <BarProvider create={() -> new BarProvider('bar')}>
        // Providers should have an @:child node that points to a function,
        // which is allowed by the API as long as the function returns a Child.
        {bar -> <div>{bar.value}</div>}
      </BarProvider>
    </div>);
  }
}
```

This should cover most of it.

This will also open up APIs like this:

```haxe
class ServerOnly extends StaticComponent {
  @:constant final label:String;

  function render() {
    return blok.html.View.islands(<div class="foo">
      // Outside an `<island>` tag, interactive attributes, like `onClick`,
      // are not allowed. Instead, all of this is simply rendered out as 
      // a string.
      <h1>"This will never get rendered on the client."</h1>
      <island>
        // Everything in here will be rendered on the client.
        <button onClick={e -> trace('yay')}>label</button>
      </island>
    </div>);
  }
}
```

Depending on the target, the above will be compiled in two ways:

```haxe
// on the server:
class ServerOnly extends StaticComponent {
  @:constant final label:String;

  function render() {
    var island0 = new Island({ 
      id: Island.createHash(this, [ label ]),
      children: blok.html.View.view(<button onClick={e -> trace('yay')}>label</button>)
    });
    return blok.html.server.StaticHtml.prepare('<div class="foo"><h1>This will never get rendered on the client.</h1>{0}</div>', island0);
  }
}

// On the client:
class ServerOnly extends StaticComponent {
  @:constant final label:String;
  
  function render() {
    var island0 = new Island({ 
      id: Island.createHash(this, [ label ]),
      children: blok.html.View.view(<button onClick={e -> trace('yay')}>label</button>)
    });
    island0.hydrateIsland();
    return null;
  }
}
```

Ideally we'll be able to just render the page as normal, but only parts of it will get hydrated on the client side. This should vastly lower the amount of JS we have to send.

I think I'm missing a lot of obvious stuff in this example (mainly: how do we handled nested StaticComponents? Frankly we need to see what React is doing with Server Components -- this may require us to have some sort of global IslandContext we can register stuff with for later hydration on the client side.)
