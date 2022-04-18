package blok.state;

import blok.core.Debug;
import blok.ui.Widget;
import blok.data.Result;

@:forward(observe, handle, peek, next, observeNext, handleNext, dispose)
abstract ObservableResult<Data, Error>(Observable<Result<Data, Error>>) 
  from Observable<Result<Data, Error>> 
{
  #if js
    @:from public static function ofPromise<Data, Error>(promise:js.lib.Promise<Data>):ObservableResult<Data, Error> {
      var obs = new ObservableResult(Suspended);
      promise.then(
        data -> obs.resume(data),
        err -> obs.fail(err) 
      );
      return obs;
    }
  #end

  @:from public static inline function ofResult<Data, Error>(result:Result<Data, Error>) {
    return new ObservableResult(result);
  }

  @:from public static function ofArray<Data, Error>(
    observables:Array<ObservableResult<Data, Error>>
  ):ObservableResult<Array<Data>, Error> {
    var remaining = observables.length;
    var content:Array<Data> = [];
    var failed:Bool = false;
    return await((resume, fail) -> {  
      for (observable in observables) {
        observable.handle(res -> switch res {
          case Suspended: 
            Pending;
          case Success(_) if (failed): 
            Handled;
          case Success(data):
            content.push(data);
            --remaining;
            if (remaining <= 0) {
              Debug.assert(!failed);
              Debug.assert(resume != null, '"resume" was called more than once.');
              resume(content);
              resume = null;
            }
            Handled;
          case Failure(_) if (failed): 
            Handled;
          case Failure(error): 
            failed = true;
            Debug.assert(fail != null, '"fail" was called more than once.');
            fail(error);
            fail = null;
            Handled;
        });
      } 
    });
  }
  
  public static inline function await<Data, Error>(handler:(
    resume:(data:Data)->Void,
    fail:(error:Error)->Void
  )->Void):ObservableResult<Data, Error> {
    var obs = new ObservableResult<Data, Error>(Suspended);
    handler(obs.resume, obs.fail);
    return obs;
  }

  public inline function new(result:Result<Data, Error>) {
    this = new Observable(result, (a, b) -> !a.equals(b));
  }

  public inline function suspend():ObservableResult<Data, Error> {
    this.update(Suspended);
    return this;
  }

  public inline function resume(data:Data):ObservableResult<Data, Error> {
    this.update(Success(data));
    return this;
  }

  public inline function fail(err:Error):ObservableResult<Data, Error> {
    this.update(Failure(err));
    return this;
  }

  public inline function map<R>(transform:(res:Result<Data, Error>)->Result<R, Error>):ObservableResult<R, Error> {
    return this.map(transform);
  }

  // @todo: There must be a more elegant/efficent way to do this.
  public function flatMap<R, E>(
    transform:(result:Result<Data, Error>)->ObservableResult<R, E>
  ):ObservableResult<R, E> {
    return await((resume, fail) -> {
      this.handle(res -> switch res {
        case Suspended: 
          Pending;
        default: 
          transform(res).handle(res -> switch res {
            case Suspended:
              Pending;
            case Success(data):
              resume(data);
              Handled;
            case Failure(error):
              fail(error);
              Handled;
          });
          Handled;
      });
    });
  }

  /**
    Shortcut to handle only a `Success(...)`.
  **/
  public inline function then<R>(handler:(data:Data)->Result<R, Error>):ObservableResult<R, Error> {
    return map(res -> switch res {
      case Suspended: Suspended;
      case Failure(error): Failure(error);
      case Success(data):
        var res = handler(data);
        Debug.assert(
          res != Suspended, 
          'Returning `Suspended` from `ObservableResult.then(...) will'
          + ' hang forever. Use `ObservableResult.pipe(...)` instead.'
        );
        return res;
    });
  }

  /**
    Shortcut to `flatMap` a `Success` into a new `ObservableResult`.
  **/
  public inline function pipe<R>(handler:(data:Data)->ObservableResult<R, Error>):ObservableResult<R, Error> {
    return flatMap(res -> switch res {
      case Suspended: Suspended;
      case Failure(error): Failure(error);
      case Success(data): handler(data);
    });
  }

  /**
    Shortcut to handle a `Failure` and convert it into a `Success`. 
  **/
  public inline function recover(handler:(error:Error)->Data):ObservableResult<Data, Error> {
    return map(res -> switch res {
      case Suspended: Suspended;
      case Failure(error): Success(handler(error));
      case Success(data): Success(data);
    });
  }

  public inline function render(build:(result:Result<Data, Error>)->Widget) {
    return this.render(build);
  }
}
