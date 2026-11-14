import 'package:aneuncheok/state/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('streak', () {
    test('starts at 0 and becomes 1 on first activity', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1, 9));
      expect(store.currentStreak, 0);

      final result = store.recordView('a');

      expect(result.streakIncreased, isTrue);
      expect(store.currentStreak, 1);
      expect(store.activeToday, isTrue);
    });

    test('same day does not increase, next day does', () {
      var now = DateTime(2026, 1, 1, 9);
      final store = ProgressStore(clock: () => now);

      store.recordView('a');
      expect(store.recordView('b').streakIncreased, isFalse);
      expect(store.currentStreak, 1);

      now = DateTime(2026, 1, 2, 23, 59);
      expect(store.recordView('c').streakIncreased, isTrue);
      expect(store.currentStreak, 2);
    });

    test('works across a month boundary', () {
      var now = DateTime(2026, 1, 31, 12);
      final store = ProgressStore(clock: () => now);
      store.recordView('a');

      now = DateTime(2026, 2, 1, 8);
      store.recordView('b');

      expect(store.currentStreak, 2);
    });

    test('missing a day resets the streak', () {
      var now = DateTime(2026, 1, 1);
      final store = ProgressStore(clock: () => now);
      store.recordView('a');
      now = DateTime(2026, 1, 2);
      store.recordView('b');
      expect(store.currentStreak, 2);

      now = DateTime(2026, 1, 4);
      // Shown as broken immediately...
      expect(store.currentStreak, 0);
      // ...and restarts from 1 on the next activity.
      store.recordView('c');
      expect(store.currentStreak, 1);
    });

    test('a reaction counts as activity', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.complete('a', newToMe: true);
      expect(store.currentStreak, 1);
    });
  });

  group('daily goal', () {
    test('reached on the fifth distinct card, once', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      final flags = [
        for (var i = 0; i < ProgressStore.dailyGoal + 2; i++)
          store.recordView('c$i').goalReached,
      ];

      expect(flags.indexOf(true), ProgressStore.dailyGoal - 1);
      expect(flags.where((f) => f), hasLength(1));
      expect(store.goalReached, isTrue);
    });

    test('viewing the same card again does not count twice', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.recordView('a');
      store.recordView('a');
      store.recordView('a');
      expect(store.todayViewed, 1);
    });

    test('resets on a new day', () {
      var now = DateTime(2026, 1, 1);
      final store = ProgressStore(clock: () => now);
      for (var i = 0; i < ProgressStore.dailyGoal; i++) {
        store.recordView('c$i');
      }
      expect(store.goalReached, isTrue);

      now = DateTime(2026, 1, 2);
      expect(store.todayViewed, 0);
      expect(store.goalReached, isFalse);
    });
  });

  group('levels', () {
    test('starts at level 1 with progress 0', () {
      final store = ProgressStore();
      expect(store.levelNumber, 1);
      expect(store.level.name, levels.first.name);
      expect(store.levelProgress, 0);
    });

    test('levels up exactly when crossing a threshold', () {
      final store = ProgressStore();
      final threshold = levels[1].minCompleted;

      for (var i = 0; i < threshold - 1; i++) {
        expect(store.complete('c$i', newToMe: true).leveledUpTo, isNull);
      }
      final result = store.complete('last', newToMe: true);

      expect(result.leveledUpTo, same(levels[1]));
      expect(store.levelNumber, 2);
    });

    test('changing a reaction does not count or level up again', () {
      final store = ProgressStore();
      store.complete('a', newToMe: true);

      final again = store.complete('a', newToMe: false);

      expect(again.firstTime, isFalse);
      expect(again.leveledUpTo, isNull);
      expect(store.completedCount, 1);
      expect(store.reactionFor('a'), isFalse);
    });

    test('reports progress toward the next level', () {
      final store = ProgressStore();
      store.complete('a', newToMe: true);
      expect(store.levelProgress, closeTo(1 / levels[1].minCompleted, 1e-9));
      expect(store.nextLevel, same(levels[1]));
    });
  });

  group('saved', () {
    test('toggleSaved flips and reports the new state', () {
      final store = ProgressStore();
      expect(store.toggleSaved('a'), isTrue);
      expect(store.isSaved('a'), isTrue);
      expect(store.savedCount, 1);
      expect(store.toggleSaved('a'), isFalse);
      expect(store.savedCount, 0);
    });

    test('save is idempotent', () {
      final store = ProgressStore();
      store.save('a');
      store.save('a');
      expect(store.savedCount, 1);
    });
  });

  group('persistence', () {
    test('state survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      DateTime clock() => DateTime(2026, 1, 1);

      final first = ProgressStore(prefs: prefs, clock: clock);
      first.recordView('a');
      first.complete('a', newToMe: true);
      first.complete('b', newToMe: false);
      first.save('b');
      await Future<void>.delayed(Duration.zero);

      final second = ProgressStore(prefs: prefs, clock: clock);

      expect(second.completedCount, 2);
      expect(second.reactionFor('a'), isTrue);
      expect(second.reactionFor('b'), isFalse);
      expect(second.isSaved('b'), isTrue);
      expect(second.currentStreak, 1);
      expect(second.todayViewed, 1);
    });

    test('corrupt data starts fresh instead of crashing', () async {
      SharedPreferences.setMockInitialValues({'progress_v1': 'not json'});
      final prefs = await SharedPreferences.getInstance();

      final store = ProgressStore(prefs: prefs);

      expect(store.completedCount, 0);
      expect(store.savedCount, 0);
      expect(store.currentStreak, 0);
    });
  });
}
