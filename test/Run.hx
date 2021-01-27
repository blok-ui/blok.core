import medic.Runner;

class Run {
  public static function main() {
    var runner = new Runner();
    runner.add(new TestComponent());
    runner.add(new TestService());
    runner.run();
  }
}

// class TestComp<T> extends Component {
//   @prop var foo:T;

//   @update
//   function setFoo(foo:T) {
//     return UpdateState({
//       foo: foo
//     });
//   }

//   @effect
//   function sayFoo() {
//     trace(foo);
//   }

//   override function render(context:Context<Node>):VNode<Node> {
//     return Html.fragment([
//       Html.h('p', {}, [ Html.text('Test!') ])
//     ]);
//   }
// }
