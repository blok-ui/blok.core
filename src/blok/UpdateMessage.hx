package blok;

enum UpdateMessage<T> {
  None;
  Update;
  UpdateState(data:T);
  UpdateStateSilent(data:T);
}
