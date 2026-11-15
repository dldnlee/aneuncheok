import 'package:aneuncheok/state/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late ProgressStore store;

  void advance(int days) {
    now = DateTime(now.year, now.month, now.day + days, 9);
  }

  setUp(() {
    now = DateTime(2026, 3, 1, 9);
    store = ProgressStore(clock: () => now);
  });

  group('the review queue', () {
    test('a card marked 몰랐어요 joins the queue, due tomorrow', () {
      store.complete('a', newToMe: true);

      expect(store.isInReview('a'), isTrue);
      expect(store.isDue('a'), isFalse);
      expect(store.dueCount, 0);
      expect(store.reviewQueueCount, 1);
      expect(store.daysUntilNextReview, 1);
      expect(store.reviewStep('a'), 1);

      advance(1);
      expect(store.isDue('a'), isTrue);
      expect(store.dueCount, 1);
      expect(store.daysUntilNextReview, 0);
    });

    test('a card you already knew never joins the queue', () {
      store.complete('a', newToMe: false);

      expect(store.isInReview('a'), isFalse);
      expect(store.reviewQueueCount, 0);
      expect(store.daysUntilNextReview, isNull);
    });

    test('changing your answer adds or removes the card', () {
      store.complete('a', newToMe: false);
      expect(store.isInReview('a'), isFalse);

      store.complete('a', newToMe: true);
      expect(store.isInReview('a'), isTrue);

      store.complete('a', newToMe: false);
      expect(store.isInReview('a'), isFalse);
    });

    test('re-reacting keeps a card on its current step', () {
      store.complete('a', newToMe: true);
      advance(1);
      store.review('a', remembered: true);
      expect(store.reviewStep('a'), 2);

      store.complete('a', newToMe: true);

      expect(store.reviewStep('a'), 2, reason: 'progress must not reset');
    });

    test('an empty queue has no next review', () {
      expect(store.daysUntilNextReview, isNull);
      expect(store.dueCount, 0);
      expect(store.dueIds(), isEmpty);
    });
  });

  group('answering', () {
    test(
      'remembering climbs the 1, 3, 7, 14, 30 day ladder, then graduates',
      () {
        store.complete('a', newToMe: true);
        advance(ReviewSchedule.intervals[0]);

        for (final wait in ReviewSchedule.intervals.skip(1)) {
          final result = store.review('a', remembered: true);

          expect(result.applied, isTrue);
          expect(result.remembered, isTrue);
          expect(result.graduated, isFalse);
          expect(result.nextInDays, wait);
          expect(store.isDue('a'), isFalse);

          advance(wait - 1);
          expect(store.isDue('a'), isFalse, reason: 'one day early');
          advance(1);
          expect(store.isDue('a'), isTrue, reason: 'exactly $wait days later');
        }

        final last = store.review('a', remembered: true);

        expect(last.graduated, isTrue);
        expect(last.nextInDays, isNull);
        expect(store.isInReview('a'), isFalse);
        expect(store.isGraduated('a'), isTrue);
        expect(store.graduatedCount, 1);
        expect(store.reviewCount, ReviewSchedule.intervals.length);
        expect(
          last.xpGained,
          greaterThanOrEqualTo(XpRewards.reviewed + XpRewards.graduated),
        );
      },
    );

    test('forgetting sends the card back to the first step', () {
      store.complete('a', newToMe: true);
      advance(1);
      store.review('a', remembered: true);
      advance(3);
      store.review('a', remembered: true);
      expect(store.reviewStep('a'), 3);
      advance(7); // wait until it is due again

      final result = store.review('a', remembered: false);
      // Forgetting is due again tomorrow, not "now": it was just answered.
      expect(result.applied, isTrue);
      expect(result.remembered, isFalse);
      expect(result.nextInDays, ReviewSchedule.intervals.first);
      expect(store.reviewStep('a'), 1);
      expect(store.isDue('a'), isFalse);
      expect(store.reviewCount, 2, reason: 'forgetting is not a success');

      advance(1);
      expect(store.isDue('a'), isTrue);
    });

    test('forgetting earns no XP for the answer itself', () {
      store.complete('a', newToMe: true);
      advance(1);
      final before = store.xp;

      final result = store.review('a', remembered: false);

      // The only XP possible here is the first-of-the-day streak bonus.
      expect(result.xpGained, XpRewards.streakBonus(store.currentStreak));
      expect(store.xp, before + result.xpGained);
    });

    test('remembering earns XP', () {
      store.complete('a', newToMe: true);
      advance(1);
      final before = store.xp;

      final result = store.review('a', remembered: true);

      expect(result.xpGained, greaterThanOrEqualTo(XpRewards.reviewed));
      expect(store.xp, before + result.xpGained);
    });

    test('a card that is not due cannot be answered', () {
      store.complete('a', newToMe: true);
      final xp = store.xp;

      final early = store.review('a', remembered: true);

      expect(early.applied, isFalse);
      expect(early.xpGained, 0);
      expect(store.xp, xp);
      expect(store.reviewStep('a'), 1);
      expect(store.reviewCount, 0);
    });

    test('an unknown card cannot be answered', () {
      expect(store.review('nope', remembered: true).applied, isFalse);
    });

    test('the same card cannot be answered twice for XP', () {
      store.complete('a', newToMe: true);
      advance(1);

      final first = store.review('a', remembered: true);
      final second = store.review('a', remembered: true);

      expect(first.applied, isTrue);
      expect(second.applied, isFalse);
      expect(store.reviewCount, 1);
    });

    test('reviewing counts as activity for the streak', () {
      store.complete('a', newToMe: true);
      advance(1);
      expect(store.activeToday, isFalse);

      store.review('a', remembered: true);

      expect(store.activeToday, isTrue);
      expect(store.currentStreak, 2);
    });

    test('a graduated card does not rejoin when re-reacted', () {
      store.complete('a', newToMe: true);
      for (var i = 0; i < ReviewSchedule.intervals.length; i++) {
        advance(31);
        store.review('a', remembered: true);
      }
      expect(store.isGraduated('a'), isTrue);

      store.complete('a', newToMe: true);

      expect(store.isInReview('a'), isFalse);
    });

    test('leveling up from a review is reported', () {
      // 26 XP is just under level 2 (30 XP): the review has to cross it.
      store.complete('a', newToMe: true);
      store.complete('b', newToMe: true);
      store.complete('k', newToMe: false);
      expect(store.xp, lessThan(levels[1].minXp));
      advance(1);

      final result = store.review('a', remembered: true);

      expect(result.leveledUpTo, same(levels[1]));
      expect(store.level, same(levels[1]));
    });
  });

  group('ordering and dates', () {
    test(
      'due cards come longest-overdue first, then by id, and are capped',
      () {
        store.complete('c', newToMe: true); // due day 1
        advance(1);
        store.complete('b', newToMe: true); // due day 2
        advance(1);
        store.complete('z', newToMe: true); // due day 3
        store.complete('y', newToMe: true); // due day 3
        advance(5);

        expect(store.dueIds(), ['c', 'b', 'y', 'z']);
        expect(store.dueIds(limit: 2), ['c', 'b']);
        expect(
          store.dueCount,
          4,
          reason: 'the cap applies to the session only',
        );
      },
    );

    test('the session limit is respected by default', () {
      for (var i = 0; i < ReviewSchedule.sessionLimit + 7; i++) {
        store.complete('card$i', newToMe: true);
      }
      advance(1);

      expect(store.dueCount, ReviewSchedule.sessionLimit + 7);
      expect(store.dueIds(), hasLength(ReviewSchedule.sessionLimit));
    });

    test('due dates work across a year boundary', () {
      now = DateTime(2026, 12, 31, 9);
      store.complete('a', newToMe: true);
      expect(store.isDue('a'), isFalse);

      advance(1); // 2027-01-01
      expect(store.isDue('a'), isTrue);
    });

    test('a long wait works across a month boundary', () {
      now = DateTime(2026, 1, 30, 9);
      store.complete('a', newToMe: true);
      advance(1);

      final result = store.review('a', remembered: true);

      expect(result.nextInDays, 3);
      expect(store.daysUntilNextReview, 3, reason: 'Jan 31 -> Feb 3');
    });

    test('February in a leap year is counted correctly', () {
      now = DateTime(2028, 2, 28, 9); // 2028 is a leap year
      store.complete('a', newToMe: true);
      advance(1); // Feb 29
      store.review('a', remembered: true); // next in 3 days

      expect(store.daysUntilNextReview, 3);
      advance(2); // Mar 2
      expect(store.isDue('a'), isFalse);
      advance(1); // Mar 3
      expect(store.isDue('a'), isTrue);
    });

    test('daysUntilNextReview reports the soonest card', () {
      store.complete('a', newToMe: true);
      advance(1);
      store.review('a', remembered: true); // a is due in 3 days
      store.complete('b', newToMe: true); // b is due tomorrow

      expect(store.daysUntilNextReview, 1);
    });
  });

  group('badges', () {
    test('복습왕 unlocks after 10 successful reviews', () {
      for (var i = 0; i < 10; i++) {
        store.complete('card$i', newToMe: true);
      }
      store.drainNewBadges();
      advance(1);
      for (var i = 0; i < 9; i++) {
        store.review('card$i', remembered: true);
      }
      expect(store.hasBadge('review_10'), isFalse);

      store.review('card9', remembered: true);

      expect(store.hasBadge('review_10'), isTrue);
    });

    test('졸업생 unlocks after 5 cards graduate', () {
      for (var i = 0; i < 5; i++) {
        store.complete('card$i', newToMe: true);
      }
      for (var round = 0; round < ReviewSchedule.intervals.length; round++) {
        advance(31);
        for (var i = 0; i < 5; i++) {
          store.review('card$i', remembered: true);
        }
      }

      expect(store.graduatedCount, 5);
      expect(store.hasBadge('graduate_5'), isTrue);
    });

    test('forgetting does not count toward 복습왕', () {
      for (var i = 0; i < 10; i++) {
        store.complete('card$i', newToMe: true);
      }
      advance(1);
      for (var i = 0; i < 10; i++) {
        store.review('card$i', remembered: false);
      }

      expect(store.reviewCount, 0);
      expect(store.hasBadge('review_10'), isFalse);
    });
  });

  group('persistence', () {
    test(
      'the queue, steps, due dates and counters survive a restart',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        DateTime clock() => now;
        final first = ProgressStore(prefs: prefs, clock: clock);
        first.complete('a', newToMe: true);
        first.complete('b', newToMe: true);
        first.complete('c', newToMe: true);
        advance(1);
        first.review('a', remembered: true); // a: step 2
        first.review('b', remembered: false); // b: back to step 1
        await Future<void>.delayed(Duration.zero);

        final second = ProgressStore(prefs: prefs, clock: clock);

        expect(second.reviewQueueCount, 3);
        expect(second.reviewStep('a'), 2);
        expect(second.reviewStep('b'), 1);
        expect(second.isDue('c'), isTrue);
        expect(second.isDue('a'), isFalse);
        expect(second.reviewCount, 1);
        expect(second.daysUntilNextReview, 0);
        expect(second.dueIds(), ['c']);
      },
    );

    test('graduated cards survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      DateTime clock() => now;
      final first = ProgressStore(prefs: prefs, clock: clock);
      first.complete('a', newToMe: true);
      for (var i = 0; i < ReviewSchedule.intervals.length; i++) {
        advance(31);
        first.review('a', remembered: true);
      }
      await Future<void>.delayed(Duration.zero);

      final second = ProgressStore(prefs: prefs, clock: clock);
      second.complete('a', newToMe: true);

      expect(second.isGraduated('a'), isTrue);
      expect(second.graduatedCount, 1);
      expect(second.isInReview('a'), isFalse);
    });

    test('saves from before review existed still load', () async {
      SharedPreferences.setMockInitialValues({
        'progress_v1':
            '{"completed":{"a":true},"saved":[],"streak":1,'
            '"lastActiveDay":"2026-03-01","viewedDay":null,"viewedToday":[],'
            '"xp":10}',
      });
      final prefs = await SharedPreferences.getInstance();

      final loaded = ProgressStore(prefs: prefs, clock: () => now);

      expect(loaded.completedCount, 1);
      expect(loaded.reviewQueueCount, 0);
      expect(loaded.graduatedCount, 0);
      expect(loaded.xp, 10);
    });

    test('malformed review data starts fresh instead of crashing', () async {
      SharedPreferences.setMockInitialValues({
        'progress_v1': '{"completed":{"a":true},"review":{"a":"oops"}}',
      });
      final prefs = await SharedPreferences.getInstance();

      final loaded = ProgressStore(prefs: prefs, clock: () => now);

      expect(loaded.reviewQueueCount, 0);
      expect(loaded.completedCount, 0);
    });
  });
}
