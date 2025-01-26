package blok.data;

import haxe.Json;

class ObjectSuite extends Suite {
	@:test(expects = 3)
	function setsUpConstructorCorrectly() {
		var simple = new SimpleObject({name: 'Foo', last: 'Bar'});
		simple.name.equals('Foo');
		simple.last.equals('Bar');
		simple.full.equals('Foo Bar');
	}

	@:test(expects = 2)
	function serializableObjectCanBeSerialized() {
		var obj = SimpleSerializableObject.fromJson({
			name: 'Jeff',
			last: 'LastName',
			other: {
				a: 'foo'
			}
		});
		obj.full.equals('Jeff LastName');
		Json.stringify(obj.toJson()).equals('{"name":"Jeff","last":"LastName","other":{"a":"foo"}}');
	}
}

class SimpleObject extends Object {
	@:value public final name:String;
	@:value public final last:String;
	@:prop(get = name + ' ' + last) public final full:String;
}

class SimpleSerializableObject extends SerializableObject {
	@:value public final name:String;
	@:value public final last:String;
	// This tests nested serializable objects:
	@:value public final other:OtherObject;
	@:prop(get = name + ' ' + last) public final full:String;
}

class OtherObject extends SerializableObject {
	@:value public final a:String;
}
