package blok.data;

import blok.signal.Runtime;
import blok.signal.Observer;

class ModelSuite extends Suite {
	@:test(expects = 3)
	function setsUpConstructorCorrectly() {
		var simple = new SimpleModel({first: 'Foo', last: 'Bar'});
		simple.first.equals('Foo');
		simple.last.peek().equals('Bar');
		simple.full.peek().equals('Foo Bar');
	}

	@:test(expects = 2)
	function reactiveFieldsAreReactive() {
		var simple = new SimpleModel({first: 'Foo', last: 'Bar'});
		var expected = 'Foo Bar';
		var obs = new Observer(() -> {
			simple.full().equals(expected);
		});

		expected = 'Foo Last';
		simple.last.set('Last');

		return Runtime.current().scheduleFuture().inspect(_ -> obs.dispose());
	}
}

class SimpleModel extends Model {
	@:value public final first:String;
	@:signal public final last:String;
	@:computed public final full:String = first + ' ' + last();
}

class SimpleSerializableModel extends SerializableModel {
	@:value public final first:String;
	@:signal public final last:String;
	@:computed public final full:String = first + ' ' + last();
}
