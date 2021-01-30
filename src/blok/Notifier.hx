package blok;

typedef Notifier<T> = {
  public function subscribe(subscription:(value:T)->Void):Disposable;
  public function notify():Void;
}
