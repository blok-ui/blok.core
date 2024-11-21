package blok.data;

class ObjectSuite extends Suite {
	@:test(expects = 3)
	function setsUpConstructorCorrectly() {
		var simple = new SimpleObject({name: 'Foo', lastName: 'Bar'});
		simple.name.equals('Foo');
		simple.lastName.equals('Bar');
		simple.fullName.equals('Foo Bar');
	}
}

class SimpleObject extends Object {
	@:value public final name:String;
	@:value public final lastName:String;
	@:prop(get = name + ' ' + lastName) public final fullName:String;
}
