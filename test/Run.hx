import medic.Runner;

class Run {
  public static function main() {
    var runner = new Runner();
    runner.add(new TestComponent());
    runner.add(new TestObservable());
    runner.add(new TestObservableResult());
    runner.add(new TestContext());
    runner.add(new TestService());
    runner.add(new TestState());
    runner.add(new TestRecord());
    runner.run();
  }
}
