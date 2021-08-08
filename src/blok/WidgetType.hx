package blok;

typedef WidgetType = Int;

var uniqueTypeId:Int = 0;

function getUniqueTypeId():WidgetType {
  return uniqueTypeId++;
}
