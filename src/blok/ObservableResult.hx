package blok;

@:forward(observe, handle, observeNext, handleNext)
abstract ObservableResult<Data, Error>(Observable<Result<Data, Error>>) 
  from Observable<Result<Data, Error>> 
{
  public static inline function await<Data, Error>(handler:(
    resume:(data:Data)->Void,
    fail:(error:Error)->Void
  )->Void) {
    var obs = new ObservableResult(Suspended);
    handler(obs.resume, obs.fail);
    return obs;
  }

  @:from public static inline function ofResult<Data, Error>(result:Result<Data, Error>) {
    return new ObservableResult(result);
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

  public inline function render(build:(result:Result<Data, Error>)->VNode) {
    return this.mapToVNode(build);
  }
}