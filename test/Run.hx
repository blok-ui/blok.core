import kit.spec.reporter.ConsoleReporter;

function main() {
  var runner = new Runner();
  
  runner.addReporter(new ConsoleReporter({
    verbose: true,
    trackProgress: true
  }));

  // @todo: We're only starting testing. Not much to see here yet.
  runner.add(blok.Signals);

  runner.run();
}
