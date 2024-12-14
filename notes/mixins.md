# Mixins

Mixins are a simple way to add functionality to a Component. They work something like this:

```haxe
class FooWatcher extends Mixin<{ 
  @:observable final foo:String;
}> {
  @:computed public final fooBar:String = view.foo() + ' bar';

  @:effect function watch() {
    trace(view.foo());
  }
}
```

This can be used with any Component that has a `foo` signal:

```haxe
class FooComponent extends Component {
  @:observable final foo:String;
  @:use final watcher:FooWatcher;

  function render() {
    return watcher.fooBar();
  }
}
```

This is expanded into something like:

```haxe
class FooComponent extends Component {
  @:observable final foo:String;
  
  var watcher(get, never):FooWatcher;
  inline function get_watcher() {
    blok.debug.Debug.assert(__watcher != null, 'Used watcher before setup');
    return __watcher;
  }
  
  var __watcher:Null<FooWatcher> = null;

  function setup() {
    __watcher = new FooWatcher(this);
    addDisposable(() -> {
      __watcher?.dispose();
      __watcher = null;
    });
  }

  function render() {
    return watcher.fooBar();
  }
}
```

Not sure if this will work, but we'll see.
