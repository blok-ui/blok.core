package blok.data;

/**
	A simple, non-reactive and non-serializable class that 
	automatically sets up constructors.
**/
@:autoBuild(blok.data.StructureBuilder.build())
abstract class Structure {}
