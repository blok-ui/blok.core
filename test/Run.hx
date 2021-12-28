import blok.state.TestState;
import medic.Runner;

function main() {
  var runner = new Runner();

  runner.add(new blok.data.TestRecord());

  runner.add(new blok.state.TestObservable());
  runner.add(new blok.state.TestObservableResult());
  runner.add(new blok.state.TestState());

  runner.add(new blok.ui.TestComponent());

  runner.add(new blok.context.TestContext());
  runner.add(new blok.context.TestService());

  runner.run();
}
