package blok.core;

import blok.context.Service;
import blok.context.Provider;
import blok.ui.Platform;

@service(fallback = new SchedulerService(DefaultScheduler.getInstance()))
class SchedulerService implements Service {
  public static function provide(build) {
    return Platform.use(platform -> 
      Provider.provide(new SchedulerService(platform.scheduler), build)
    );
  }

  final scheduler:Scheduler;

  public function new(scheduler) {
    this.scheduler = scheduler;
  }

  public function getScheduler():Scheduler {
    return scheduler;
  }
}
