package blok.data;

enum Result<Data, Error> {
  Suspended;
  Success(data:Data);
  Failure(error:Error);
}
