import blok.context.TestContext;
import medic.DefaultReporter;
import medic.Runner;

function main() {
  var runner = new Runner(new DefaultReporter({
    trackProgress: true,
    verbose: true
  }));

  runner.add(new blok.data.TestRecord());

  runner.add(new blok.state.TestObservable());
  runner.add(new blok.state.TestObservableResult());
  runner.add(new blok.state.TestState());

  runner.add(new blok.ui.TestComponent());
  runner.add(new blok.ui.TestFragment());

  runner.add(new blok.provide.TestProvider());
  runner.add(new blok.provide.TestContext());

  runner.add(new blok.context.TestContext());
  runner.add(new blok.context.TestService());

  runner.run();
}
