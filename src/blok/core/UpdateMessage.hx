package blok.core;

enum UpdateMessage<T> {
  None;
  Update;
  UpdateState(data:T);
  UpdateStateSilent(data:T);
}
