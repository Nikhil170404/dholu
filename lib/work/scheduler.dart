import 'package:workmanager/workmanager.dart';

const taskMorning = 'dholu_morning_summary';
const taskReminder = 'dholu_reminder';

/// How long until the next [hour]:[minute] (today if still ahead, otherwise tomorrow).
Duration delayUntilNext(DateTime now, int hour, int minute) {
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) {
    next = next.add(const Duration(days: 1));
  }
  return next.difference(now);
}

/// Inexact WorkManager scheduling (brief section 8): no exact-alarm permission is needed.
/// The morning task re-registers itself after each run, so it survives reboots and Doze.
abstract class AppScheduler {
  Future<void> scheduleMorning(int hour, int minute, {DateTime? now});
  Future<void> cancelMorning();
  Future<void> remindIn(int eventId, {int minutes = 10});
}

class Scheduler implements AppScheduler {
  const Scheduler();

  @override
  Future<void> scheduleMorning(int hour, int minute, {DateTime? now}) =>
      Workmanager().registerOneOffTask(
        taskMorning,
        taskMorning,
        initialDelay: delayUntilNext(now ?? DateTime.now(), hour, minute),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

  @override
  Future<void> cancelMorning() => Workmanager().cancelByUniqueName(taskMorning);

  /// "10 min baad yaad dilao".
  @override
  Future<void> remindIn(int eventId, {int minutes = 10}) =>
      Workmanager().registerOneOffTask(
        '$taskReminder-$eventId',
        taskReminder,
        initialDelay: Duration(minutes: minutes),
        inputData: {'eventId': eventId},
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
}
