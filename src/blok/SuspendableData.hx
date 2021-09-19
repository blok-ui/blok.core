package blok;

import blok.Suspend.SuspensionRequest;

enum SuspendableDataStatus<T> {
  Suspended;
  Ready(data:T);
}

/**
  Data that is either Suspended or Ready. Use inside `Suspend.await` to
  suspend rendering while you wait for an async request to process, and
  simply call `SuspendableData.set(...)` when the data is ready.
**/
@:forward(dispose)
abstract SuspendableData<T>(Observable<SuspendableDataStatus<T>>) to Disposable {
  public static inline function suspended<T>():SuspendableData<T> {
    return new SuspendableData(Suspended);
  }

  public static inline function of<T>(value:T):SuspendableData<T> {
    return new SuspendableData(Ready(value));
  }

  public inline function new(initialState) {
    this = new Observable(initialState);
  }

  public inline function suspend() {
    this.update(Suspended);
  }

  public inline function set(data:T) {
    this.update(Ready(data));
  }

  public function get() {
    return switch this.value {
      case Suspended:
        throw new SuspensionRequest(resume -> {
          this.handle(status -> switch status {
            case Ready(_): 
              resume();
              Handled;
            case Suspended:
              Pending;
          });
        });
      case Ready(data):
        data;
    }
  }
}
