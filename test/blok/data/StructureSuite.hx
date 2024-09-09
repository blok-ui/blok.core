package blok.data;

class StructureSuite extends Suite {
	@:test(expects = 3)
	function setsUpConstructorCorrectly() {
		var simple = new SimpleStructure({name: 'Foo', lastName: 'Bar'});
		simple.name.equals('Foo');
		simple.lastName.equals('Bar');
		simple.fullName.equals('Foo Bar');
	}
}

class SimpleStructure extends Structure {
	@:constant public final name:String;
	@:constant public final lastName:String;
	@:prop(get = name + ' ' + lastName) public final fullName:String;
}
