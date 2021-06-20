package blok;

typedef VNodeType = Int;

var uniqueTypeId:Int = 0;

function getUniqueTypeId():VNodeType {
  return uniqueTypeId++;
}
