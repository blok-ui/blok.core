package blok;

enum Result<Data, Error> {
  Suspended;
  Success(data:Data);
  Failure(error:Error);
}
