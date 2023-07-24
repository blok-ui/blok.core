Component and Model Hooks
=========================

You can create Components like this:

```haxe
class Foo extends Component {
  @:observable final foo:String;

  // Note: Component constructors must be private.
  function new() {
    // Run any code you want here -- all fields will be initialized
    // by this point.
    Debug.assert(foo != 'bar');
  }

  function setup() {
    // This code will be run once *after* the component has been mounted.
    Observer.track(() -> {
      trace(foo());
    });
  }

  function render():Child {
    return foo();
  }
}
```

Basically, `new` becomes a hook that is run when the class is constructed (as normal), while `setup` is a hook you can use when the component is mounted in the dom (or whatever) and can access its real node.

The same can be done with models:

```haxe
class Foo extends Model {
  @:signal public final foo:String;

  public function new() {
    trace(foo());
  }
}
```

Note that in both cases the expression will be untracked, meaning that invoking signals in a constructor will never cause dependencies to be registered.
