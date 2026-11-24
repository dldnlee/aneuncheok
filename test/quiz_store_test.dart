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

  group('XP per answer', () {
    test('grows with the combo and stops growing at the cap', () {
      final xp = [
        for (var combo = 1; combo <= 9; combo++) XpRewards.quizAnswerXp(combo),
      ];

      expect(xp, [5, 6, 7, 8, 9, 9, 9, 9, 9]);
    });

    test('a combo of zero or less still pays the base amount', () {
      expect(XpRewards.quizAnswerXp(0), XpRewards.quizCorrect);
      expect(XpRewards.quizAnswerXp(-3), XpRewards.quizCorrect);
    });

    test('a correct answer pays XP and is counted', () {
      final result = store.quizAnswer('a', correct: true, combo: 1);

      expect(result.xpGained, XpRewards.quizAnswerXp(1));
      expect(store.xp, XpRewards.quizAnswerXp(1));
      expect(store.quizCorrect, 1);
      expect(store.bestQuizCombo, 1);
    });

    test('a combo pays more and the best combo is remembered', () {
      store.quizAnswer('a', correct: true, combo: 1);
      final third = store.quizAnswer('c', correct: true, combo: 3);
      store.quizAnswer('d', correct: true, combo: 1);

      expect(third.xpGained, XpRewards.quizAnswerXp(3));
      expect(store.bestQuizCombo, 3);
    });

    test('a wrong answer pays nothing and is not counted', () {
      final result = store.quizAnswer('a', correct: false);

      expect(result.xpGained, 0);
      expect(store.xp, 0);
      expect(store.quizCorrect, 0);
    });
  });

  group('wrong answers feed the review queue', () {
    test('a missed card joins the queue, due tomorrow', () {
      store.quizAnswer('a', correct: false);

      expect(store.isInReview('a'), isTrue);
      expect(store.reviewStep('a'), 1);
      expect(store.isDue('a'), isFalse);
      advance(1);
      expect(store.isDue('a'), isTrue);
    });

    test('a card you said you knew is queued when you miss it', () {
      store.complete('a', newToMe: false);
      expect(store.isInReview('a'), isFalse);

      store.quizAnswer('a', correct: false);

      expect(store.isInReview('a'), isTrue);
    });

    test('a card already on a later step keeps its place', () {
      store.complete('a', newToMe: true);
      advance(1);
      store.review('a', remembered: true);
      expect(store.reviewStep('a'), 2);

      store.quizAnswer('a', correct: false);

      expect(store.reviewStep('a'), 2, reason: 'progress is not reset');
    });

    test('a graduated card starts the ladder again', () {
      store.complete('a', newToMe: true);
      for (var i = 0; i < ReviewSchedule.intervals.length; i++) {
        advance(31);
        store.review('a', remembered: true);
      }
      expect(store.isGraduated('a'), isTrue);

      store.quizAnswer('a', correct: false);

      expect(store.isGraduated('a'), isFalse);
      expect(store.isInReview('a'), isTrue);
      expect(store.reviewStep('a'), 1);
    });

    test('a correct answer never touches the queue', () {
      store.complete('a', newToMe: true);
      final step = store.reviewStep('a');

      store.quizAnswer('a', correct: true, combo: 1);

      expect(store.reviewStep('a'), step);
      expect(store.reviewQueueCount, 1);
    });
  });

  group('daily XP cap', () {
    test('a flawless round earns exactly the whole allowance', () {
      var xp = 0;
      for (var combo = 1; combo <= 10; combo++) {
        xp += store.quizAnswer('c$combo', correct: true, combo: combo).xpGained;
      }
      xp += store.quizRoundFinished(correct: 10, perfect: true).xpGained;

      expect(xp, XpRewards.quizDailyCap);
      expect(store.quizXpLeftToday, 0);
    });

    test('answers stop paying once the allowance is used up', () {
      for (var i = 0; i < 40; i++) {
        store.quizAnswer('c$i', correct: true, combo: 1);
      }
      final xpBefore = store.xp;

      final extra = store.quizAnswer('more', correct: true, combo: 5);

      expect(xpBefore, XpRewards.quizDailyCap);
      expect(extra.xpGained, 0);
      expect(store.xp, xpBefore);
      expect(store.quizXpLeftToday, 0);
      expect(store.quizCorrect, 41, reason: 'answers still count as answers');
    });

    test('the last payout is trimmed to what is left', () {
      // 19 answers x 5 XP = 95 XP; the next 5-XP answer fits, then 0 left.
      for (var i = 0; i < 19; i++) {
        store.quizAnswer('c$i', correct: true, combo: 1);
      }
      expect(store.quizXpLeftToday, 5);

      final result = store.quizAnswer('x', correct: true, combo: 9);

      expect(result.xpGained, 5, reason: 'a 9-XP answer is trimmed to 5');
      expect(store.quizXpLeftToday, 0);
    });

    test('the perfect bonus is also subject to the cap', () {
      for (var i = 0; i < 20; i++) {
        store.quizAnswer('c$i', correct: true, combo: 1);
      }
      final xp = store.xp;

      final result = store.quizRoundFinished(correct: 10, perfect: true);

      expect(result.xpGained, 0);
      expect(store.xp, xp);
      expect(store.perfectRounds, 1, reason: 'the achievement still counts');
    });

    test('the allowance resets the next day', () {
      for (var i = 0; i < 20; i++) {
        store.quizAnswer('c$i', correct: true, combo: 1);
      }
      expect(store.quizXpLeftToday, 0);

      advance(1);

      expect(store.quizXpLeftToday, XpRewards.quizDailyCap);
      final result = store.quizAnswer('fresh', correct: true, combo: 1);
      // Today is also the first activity of a new day, so a streak bonus may
      // come on top of the quiz XP.
      expect(
        result.xpGained,
        XpRewards.quizAnswerXp(1) + XpRewards.streakBonus(store.currentStreak),
      );
    });

    test('wrong answers and finishing a round never use the allowance', () {
      store.quizAnswer('a', correct: false);
      store.quizRoundFinished(correct: 0);

      expect(store.quizXpLeftToday, XpRewards.quizDailyCap);
    });
  });

  group('finishing a round', () {
    test('counts the round and remembers the best score', () {
      store.quizRoundFinished(correct: 6);
      store.quizRoundFinished(correct: 9);
      store.quizRoundFinished(correct: 4);

      expect(store.quizRounds, 3);
      expect(store.bestQuizScore, 9);
      expect(store.perfectRounds, 0);
    });

    test('only a perfect round pays the bonus', () {
      final plain = store.quizRoundFinished(correct: 9);
      expect(plain.xpGained, 0);

      final perfect = store.quizRoundFinished(correct: 10, perfect: true);
      expect(perfect.xpGained, XpRewards.quizPerfect);
      expect(store.perfectRounds, 1);
    });
  });

  group('activity', () {
    test('answering counts for the streak', () {
      expect(store.activeToday, isFalse);

      store.quizAnswer('a', correct: false);

      expect(store.activeToday, isTrue);
      expect(store.currentStreak, 1);
    });

    test('a quiz can level the player up', () {
      for (var i = 0; i < 5; i++) {
        store.complete('k$i', newToMe: false); // 30 XP -> level 2 already
      }
      final level = store.level;
      Level? up;
      for (var i = 0; i < 40 && up == null; i++) {
        up = store.quizAnswer('q$i', correct: true, combo: 1).leveledUpTo;
      }

      expect(up, isNotNull);
      expect(store.level.minXp, greaterThan(level.minXp));
    });
  });

  group('badges', () {
    test('퀴즈 입문 comes with the first finished round', () {
      store.quizAnswer('a', correct: true);
      expect(
        store.hasBadge('quiz_first'),
        isFalse,
        reason: 'not until it ends',
      );

      store.quizRoundFinished(correct: 1);

      expect(store.hasBadge('quiz_first'), isTrue);
    });

    test('만점! needs a perfect round', () {
      store.quizRoundFinished(correct: 9);
      expect(store.hasBadge('quiz_perfect'), isFalse);

      store.quizRoundFinished(correct: 10, perfect: true);

      expect(store.hasBadge('quiz_perfect'), isTrue);
    });

    test('퀴즈 달인 needs 50 correct answers', () {
      for (var i = 0; i < 49; i++) {
        store.quizAnswer('c$i', correct: true);
      }
      expect(store.hasBadge('quiz_50'), isFalse);

      store.quizAnswer('last', correct: true);

      expect(store.hasBadge('quiz_50'), isTrue);
    });
  });

  group('persistence', () {
    test('quiz stats and the daily allowance survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      DateTime clock() => now;
      final first = ProgressStore(prefs: prefs, clock: clock);
      for (var combo = 1; combo <= 4; combo++) {
        first.quizAnswer('c$combo', correct: true, combo: combo);
      }
      first.quizAnswer('miss', correct: false);
      first.quizRoundFinished(correct: 4);
      await Future<void>.delayed(Duration.zero);

      final second = ProgressStore(prefs: prefs, clock: clock);

      expect(second.quizCorrect, 4);
      expect(second.bestQuizCombo, 4);
      expect(second.quizRounds, 1);
      expect(second.bestQuizScore, 4);
      expect(second.quizXpLeftToday, first.quizXpLeftToday);
      expect(second.quizXpLeftToday, lessThan(XpRewards.quizDailyCap));
      expect(second.isInReview('miss'), isTrue);
    });

    test('saves from before the quiz existed still load', () async {
      SharedPreferences.setMockInitialValues({
        'progress_v1': '{"completed":{"a":true},"xp":10}',
      });
      final prefs = await SharedPreferences.getInstance();

      final loaded = ProgressStore(prefs: prefs, clock: () => now);

      expect(loaded.completedCount, 1);
      expect(loaded.quizRounds, 0);
      expect(loaded.quizCorrect, 0);
      expect(loaded.bestQuizScore, 0);
      expect(loaded.quizXpLeftToday, XpRewards.quizDailyCap);
    });
  });
}
