import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/models/knowledge_item.dart';
import 'package:aneuncheok/state/badges.dart';
import 'package:aneuncheok/state/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

KnowledgeItem item(String id, String category) =>
    KnowledgeItem(id: id, categoryId: category, title: id, content: id);

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

    test('missing a day resets the streak but remembers the best', () {
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
      expect(store.bestStreak, 2);
    });

    test('a reaction counts as activity', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.complete('a', newToMe: true);
      expect(store.currentStreak, 1);
    });
  });

  group('daily goal', () {
    test('reached on the fifth distinct card, once, for bonus XP', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      final results = [
        for (var i = 0; i < ProgressStore.dailyGoal + 2; i++)
          store.recordView('c$i'),
      ];

      final flags = results.map((r) => r.goalReached).toList();
      expect(flags.indexOf(true), ProgressStore.dailyGoal - 1);
      expect(flags.where((f) => f), hasLength(1));
      expect(
        results[ProgressStore.dailyGoal - 1].xpGained,
        XpRewards.dailyGoal,
      );
      expect(store.goalReached, isTrue);
      expect(store.goalDays, 1);
      expect(store.xp, XpRewards.dailyGoal);
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

  group('xp', () {
    test('new-to-me is worth more than already-known', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));

      expect(store.complete('a', newToMe: true).xpGained, XpRewards.newToMe);
      expect(
        store.complete('b', newToMe: false).xpGained,
        XpRewards.alreadyKnew,
      );
      expect(store.xp, XpRewards.newToMe + XpRewards.alreadyKnew);
    });

    test('changing a reaction does not farm XP', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.complete('a', newToMe: false);
      final xp = store.xp;

      final again = store.complete('a', newToMe: true);

      expect(again.firstTime, isFalse);
      expect(again.xpGained, 0);
      expect(store.xp, xp);
      expect(store.reactionFor('a'), isTrue);
    });

    test('streak bonus grows daily and is capped at 7 days', () {
      var now = DateTime(2026, 1, 1);
      final store = ProgressStore(clock: () => now);
      final bonuses = <int>[];
      for (var day = 0; day < 10; day++) {
        now = DateTime(2026, 1, 1 + day);
        bonuses.add(store.recordView('d$day').xpGained);
      }

      expect(bonuses, [0, 10, 15, 20, 25, 30, 35, 35, 35, 35]);
    });
  });

  group('levels', () {
    test('starts at level 1 with progress 0', () {
      final store = ProgressStore();
      expect(store.levelNumber, 1);
      expect(store.level, same(levels.first));
      expect(store.levelProgress, 0);
    });

    test('levels are strictly increasing so progress never divides by 0', () {
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i].minXp, greaterThan(levels[i - 1].minXp));
      }
      expect(levelForXp(0), same(levels.first));
      expect(levelForXp(levels[2].minXp), same(levels[2]));
      expect(levelForXp(levels[2].minXp - 1), same(levels[1]));
      expect(levelNumberForXp(99999), levels.length);
    });

    test('levels up exactly when crossing a threshold', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      final reactions = levels[1].minXp ~/ XpRewards.newToMe;

      for (var i = 0; i < reactions - 1; i++) {
        expect(store.complete('c$i', newToMe: true).leveledUpTo, isNull);
      }
      final result = store.complete('last', newToMe: true);

      expect(result.leveledUpTo, same(levels[1]));
      expect(store.levelNumber, 2);
    });

    test('progress is measured in XP toward the next level', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.complete('a', newToMe: true);
      expect(store.levelProgress, closeTo(10 / levels[1].minXp, 1e-9));
      expect(store.nextLevel, same(levels[1]));
    });

    test('top level reports full progress and no next level', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      // 90 reactions x 10 XP is well past the top threshold.
      for (var i = 0; i < 90; i++) {
        store.complete('c$i', newToMe: true);
      }
      expect(store.level, same(levels.last));
      expect(store.nextLevel, isNull);
      expect(store.levelProgress, 1);
    });
  });

  group('weekly xp', () {
    test('accumulates within a week and resets on Monday', () {
      // Jan 1 2026 is a Thursday; the week runs Mon Dec 29 - Sun Jan 4.
      var now = DateTime(2026, 1, 1, 9);
      final store = ProgressStore(clock: () => now);
      store.complete('a', newToMe: true);
      now = DateTime(2026, 1, 4, 22); // Sunday
      store.complete('b', newToMe: true);
      expect(store.weeklyXp, 20 + XpRewards.streakBonus(1));
      expect(store.xp, store.weeklyXp);

      now = DateTime(2026, 1, 5, 8); // Monday: new week
      expect(store.weeklyXp, 0);
      expect(store.xp, greaterThan(0), reason: 'total XP is not reset');

      store.complete('c', newToMe: false);
      expect(store.weeklyXp, greaterThan(0));
      expect(store.weeklyXp, lessThan(store.xp));
    });

    test('daysLeftInWeek counts down to Sunday', () {
      var now = DateTime(2026, 1, 5); // Monday
      final store = ProgressStore(clock: () => now);
      expect(store.daysLeftInWeek, 7);
      now = DateTime(2026, 1, 11); // Sunday
      expect(store.daysLeftInWeek, 1);
    });
  });

  group('category mastery', () {
    test('finishing a category pays a one-time bonus', () {
      final store = ProgressStore(
        clock: () => DateTime(2026, 1, 1),
        items: [item('x1', 'x'), item('x2', 'x'), item('y1', 'y')],
      );

      final first = store.complete('x1', newToMe: true);
      expect(first.masteredCategoryId, isNull);

      final last = store.complete('x2', newToMe: true);
      expect(last.masteredCategoryId, 'x');
      expect(last.xpGained, XpRewards.newToMe + XpRewards.categoryMastery);

      // Re-reacting must not pay again.
      final again = store.complete('x2', newToMe: false);
      expect(again.masteredCategoryId, isNull);
      expect(again.xpGained, 0);
    });
  });

  group('badges', () {
    test('catalog has unique ids and a badge for every category', () {
      final catalog = buildBadges(
        categories: categories,
        items: knowledgeItems,
      );
      final ids = catalog.map((b) => b.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      for (final c in categories) {
        expect(ids, contains('master_${c.id}'));
      }
      expect(catalog.every((b) => b.goal > 0), isTrue);
    });

    test('first reaction unlocks "첫걸음" exactly once', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      expect(store.badgeCount, 0);

      store.complete('a', newToMe: true);
      final fresh = store.drainNewBadges();

      expect(fresh.map((b) => b.id), contains('first_step'));
      expect(store.hasBadge('first_step'), isTrue);

      store.complete('b', newToMe: true);
      expect(
        store.drainNewBadges().map((b) => b.id),
        isNot(contains('first_step')),
      );
    });

    test('draining clears the queue', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.complete('a', newToMe: true);
      expect(store.drainNewBadges(), isNotEmpty);
      expect(store.drainNewBadges(), isEmpty);
    });

    test('daily goal, saving and sharing unlock their badges', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      for (var i = 0; i < ProgressStore.dailyGoal; i++) {
        store.recordView('v$i');
      }
      expect(store.hasBadge('goal_1'), isTrue);

      for (var i = 0; i < 10; i++) {
        store.save('s$i');
      }
      expect(store.hasBadge('collector'), isTrue);

      for (var i = 0; i < 5; i++) {
        store.recordShare();
      }
      expect(store.hasBadge('sharer'), isTrue);
      expect(store.shares, 5);
    });

    test('streak badge uses the best streak even after it breaks', () {
      var now = DateTime(2026, 1, 1);
      final store = ProgressStore(clock: () => now);
      for (var d = 0; d < 3; d++) {
        now = DateTime(2026, 1, 1 + d);
        store.recordView('d$d');
      }
      expect(store.hasBadge('streak_3'), isTrue);

      now = DateTime(2026, 1, 20);
      expect(store.currentStreak, 0);
      expect(store.hasBadge('streak_3'), isTrue);
    });

    test('mastery and all-clear badges unlock on a small data set', () {
      final store = ProgressStore(
        clock: () => DateTime(2026, 1, 1),
        items: [item('x1', 'daily'), item('x2', 'daily')],
      );

      store.complete('x1', newToMe: true);
      expect(store.hasBadge('master_daily'), isFalse);
      store.complete('x2', newToMe: true);

      expect(store.hasBadge('master_daily'), isTrue);
      expect(store.hasBadge('all_clear'), isTrue);
    });

    test('progress is reported but capped at the goal', () {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      final collector = store.badges.firstWhere((b) => b.id == 'collector');

      for (var i = 0; i < 4; i++) {
        store.save('s$i');
      }
      expect(store.badgeProgress(collector), 4);

      for (var i = 4; i < 15; i++) {
        store.save('s$i');
      }
      expect(store.badgeProgress(collector), collector.goal);
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
      first.recordShare();
      await Future<void>.delayed(Duration.zero);

      final second = ProgressStore(prefs: prefs, clock: clock);

      expect(second.completedCount, 2);
      expect(second.reactionFor('a'), isTrue);
      expect(second.reactionFor('b'), isFalse);
      expect(second.isSaved('b'), isTrue);
      expect(second.currentStreak, 1);
      expect(second.todayViewed, 1);
      expect(second.xp, first.xp);
      expect(second.weeklyXp, first.weeklyXp);
      expect(second.shares, 1);
      expect(second.hasBadge('first_step'), isTrue);
      expect(second.badgeCount, first.badgeCount);
    });

    test('progress saved before XP existed is migrated', () async {
      SharedPreferences.setMockInitialValues({
        'progress_v1':
            '{"completed":{"a":true,"b":false},"saved":[],"streak":1,'
            '"lastActiveDay":"2026-01-01","viewedDay":null,"viewedToday":[]}',
      });
      final prefs = await SharedPreferences.getInstance();

      final store = ProgressStore(
        prefs: prefs,
        clock: () => DateTime(2026, 1, 1),
      );

      expect(store.xp, XpRewards.newToMe + XpRewards.alreadyKnew);
      expect(store.completedCount, 2);
    });

    test('corrupt data starts fresh instead of crashing', () async {
      SharedPreferences.setMockInitialValues({'progress_v1': 'not json'});
      final prefs = await SharedPreferences.getInstance();

      final store = ProgressStore(prefs: prefs);

      expect(store.completedCount, 0);
      expect(store.savedCount, 0);
      expect(store.currentStreak, 0);
      expect(store.xp, 0);
      expect(store.badgeCount, 0);
    });
  });
}
