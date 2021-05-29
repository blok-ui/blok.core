package blok;

typedef VNodeType = Int;

final fragmentType:VNodeType = -1;

var uniqueTypeId:Int = 0;

function getUniqueTypeId():VNodeType {
  return uniqueTypeId++;
}
