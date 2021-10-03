Result
======

Right now, error-handling and (especially) the Suspend system are really brittle and overcomplicated.

Instead of trying to ape React's system for Suspend, what if we took a more Elm approach? We have Observables, and Haxe already has great Enum support. Let's leverage that.

This would also mean stripping out our error catching stuff entirely, and pushing the user to use Option or (tink-style) Outcomes instead. We might go ahead and add a `Result` class, come to think of it.

Something like this:

```haxe
package blok;

enum Result<Data, Error> {
  Success(data:Data);
  Failure(error:Error);
  Suspended;
}
```

All loading could then be handled by `Observable<Result<T>>`, something that should be common enough to justify an `ObservableResult<T>` class.

Usage would be something like this:

```haxe
class Example extends Component {
  @prop var data:Promise<String>; // pretend we're using tink.

  function render() {
    return Html.div({},
      ObservableResult
        .await(obs -> {
          data.handle(o -> switch o {
            case Success(data):
              obs.update(Success(data));
            case Failure(err):
              obs.update(Failure(err));
          });
        }).show(result -> switch result {
          case Suspended: Html.text('loading...');
          case Success(data): Html.text(data);
          case Failure(err): Html.text(err.message);
        })
    );
  }
}

```

The main issue here is that this will break hydration, but we can think on ways to integrate Result as Blok's async system. Perhaps we'll need a ResultComponent to let us hook into it?
