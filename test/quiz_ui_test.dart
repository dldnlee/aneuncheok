import 'dart:math';

import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/quiz/quiz_generator.dart';
import 'package:aneuncheok/screens/quiz_screen.dart';
import 'package:aneuncheok/state/progress_store.dart';
import 'package:aneuncheok/widgets/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

const _prompt = '이 설명은 어떤 상식일까요?';
const _next = '다음 문제 →';
const _seeResult = '결과 보기';

/// [n] fixed questions about daily-life cards, in a known order.
List<QuizQuestion> fixedQuestions(int n) {
  final pool = knowledgeItems.where((i) => i.categoryId == 'daily').take(n);
  return buildQuiz(
    pool: pool.toList(),
    all: knowledgeItems,
    random: Random(3),
    count: n,
  );
}

String right(QuizQuestion q) => q.options[q.correctIndex].title;

String wrong(QuizQuestion q) =>
    q.options.firstWhere((o) => o.id != q.item.id).title;

/// Pushes the quiz with fixed questions on top of the running app.
Future<void> openQuiz(WidgetTester tester, List<QuizQuestion> questions) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => QuizScreen(questions: questions)),
  );
  await tester.pumpAndSettle();
}

Future<void> answer(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

Future<void> goNext(WidgetTester tester) async {
  final next = find.text(_next);
  await tester.tap(next.evaluate().isNotEmpty ? next : find.text(_seeResult));
  await tester.pumpAndSettle();
}

int hearts(WidgetTester tester) =>
    find.byIcon(Icons.favorite_rounded).evaluate().length;

void main() {
  late ProgressStore progress;

  setUp(() {
    progress = ProgressStore(clock: () => testNow);
  });

  group('the home card', () {
    testWidgets('is locked until enough cards are learned', (tester) async {
      for (var i = 1; i <= 3; i++) {
        progress.complete('d$i', newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      expect(find.text('퀴즈 챌린지'), findsOneWidget);
      expect(
        find.text(
          '상식을 ${QuizConfig.minCards}개 알아보면 열려요 (3/${QuizConfig.minCards})',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      await tester.tap(find.text('퀴즈 챌린지'));
      await tester.pumpAndSettle();
      expect(find.text(_prompt), findsNothing, reason: 'still locked');
    });

    testWidgets('opens once five cards are learned', (tester) async {
      for (var i = 1; i <= QuizConfig.minCards; i++) {
        progress.complete('d$i', newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      expect(find.text('10문제 · 하트 3개'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);

      await tester.tap(find.text('퀴즈 챌린지'));
      await tester.pumpAndSettle();

      expect(find.text(_prompt), findsOneWidget);
      expect(find.text('1 / ${QuizConfig.minCards}'), findsOneWidget);
    });

    testWidgets('shows the best score after a round', (tester) async {
      for (var i = 1; i <= 5; i++) {
        progress.complete('d$i', newToMe: true);
      }
      progress.quizRoundFinished(correct: 7);
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      expect(find.text('최고 기록 7점 · 또 도전해요!'), findsOneWidget);
    });

    testWidgets('says so when today\'s quiz XP is used up', (tester) async {
      for (var i = 1; i <= 5; i++) {
        progress.complete('d$i', newToMe: true);
      }
      for (var i = 0; i < 25; i++) {
        progress.quizAnswer('q$i', correct: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      expect(find.textContaining('오늘 XP 완료'), findsOneWidget);
    });
  });

  group('a question', () {
    testWidgets('shows a mystery, the masked explanation and four options', (
      tester,
    ) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);
      final q = qs.first;

      expect(find.text(_prompt), findsOneWidget);
      expect(find.text('❓'), findsOneWidget);
      expect(find.text(q.masked), findsOneWidget);
      for (final option in q.options) {
        expect(find.text(option.title), findsOneWidget);
      }
      expect(find.text('1 / 5'), findsOneWidget);
      expect(hearts(tester), QuizConfig.lives);
    });

    testWidgets('a right answer is celebrated, paid and reveals the emoji', (
      tester,
    ) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);
      final q = qs.first;

      await tester.tap(find.text(right(q)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('+${XpRewards.quizAnswerXp(1)} XP'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
      expect(
        find.text('❓'),
        findsNothing,
        reason: 'the card emoji replaces it',
      );
      expect(find.text(q.item.emoji!), findsOneWidget);
      expect(progress.quizCorrect, 1);
      expect(progress.xp, XpRewards.quizAnswerXp(1));
      expect(hearts(tester), QuizConfig.lives);
    });

    testWidgets('a wrong answer costs a heart and shows the right one', (
      tester,
    ) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);
      final q = qs.first;

      await answer(tester, wrong(q));

      expect(hearts(tester), QuizConfig.lives - 1);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(progress.quizCorrect, 0);
      expect(progress.xp, 0);
    });

    testWidgets('a wrong answer sends the card to review', (tester) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      await answer(tester, wrong(qs.first));

      expect(progress.isInReview(qs.first.item.id), isTrue);
    });

    testWidgets('options are locked once answered', (tester) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);
      final q = qs.first;

      await answer(tester, right(q));
      await tester.tap(find.text(wrong(q)));
      await tester.pumpAndSettle();

      expect(progress.quizCorrect, 1);
      expect(hearts(tester), QuizConfig.lives, reason: 'no second answer');
    });

    testWidgets('right answers in a row build a combo', (tester) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      await answer(tester, right(qs[0]));
      expect(
        find.textContaining('콤보'),
        findsNothing,
        reason: 'one is not a combo',
      );
      await goNext(tester);
      await answer(tester, right(qs[1]));

      expect(find.text('🔥 2 콤보'), findsOneWidget);

      await goNext(tester);
      await answer(tester, wrong(qs[2]));
      expect(
        find.textContaining('콤보'),
        findsNothing,
        reason: 'a miss resets it',
      );
    });

    testWidgets('next moves to a different question', (tester) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      await answer(tester, right(qs[0]));
      await goNext(tester);

      expect(find.text('2 / 5'), findsOneWidget);
      expect(find.text(qs[1].masked), findsOneWidget);
      expect(find.text(qs[0].masked), findsNothing);
      expect(find.text('❓'), findsOneWidget);
    });

    testWidgets('the explanation never contains the answer\'s own title', (
      tester,
    ) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      for (var i = 0; i < qs.length; i++) {
        expect(find.text(qs[i].masked), findsOneWidget);
        expect(qs[i].masked.contains(qs[i].item.title), isFalse);
        await answer(tester, right(qs[i]));
        await dismissDialogs(tester);
        if (i < qs.length - 1) await goNext(tester);
      }
    });
  });

  group('a round', () {
    testWidgets('a flawless round pays the bonus and earns two badges', (
      tester,
    ) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      for (var i = 0; i < qs.length; i++) {
        await answer(tester, right(qs[i]));
        if (i < qs.length - 1) {
          await goNext(tester);
        }
      }
      await dismissDialogs(tester);
      expect(progress.hasBadge('quiz_first'), isTrue);
      expect(progress.hasBadge('quiz_perfect'), isTrue);

      await goNext(tester);

      // 5 + 6 + 7 + 8 + 9 for the combo, plus the 20-XP perfect bonus.
      const expected = 5 + 6 + 7 + 8 + 9 + XpRewards.quizPerfect;
      expect(find.text('5 / 5 정답!'), findsOneWidget);
      expect(find.text('만점이에요! 대단해요 🎊'), findsOneWidget);
      expect(find.text('⭐ +$expected XP'), findsOneWidget);
      expect(find.text('🔥 최고 5 콤보'), findsOneWidget);
      expect(find.text('🎖️ 새 기록!'), findsOneWidget);
      expect(find.text('🏆'), findsOneWidget);
      expect(progress.xp, expected);
      expect(progress.quizRounds, 1);
      expect(progress.perfectRounds, 1);
    });

    testWidgets('three wrong answers end the round early', (tester) async {
      final qs = fixedQuestions(6);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      for (var i = 0; i < QuizConfig.lives; i++) {
        await answer(tester, wrong(qs[i]));
        if (i < QuizConfig.lives - 1) await goNext(tester);
      }

      expect(hearts(tester), 0);
      expect(
        find.text(_seeResult),
        findsOneWidget,
        reason: 'no more questions',
      );
      await dismissDialogs(tester);
      await goNext(tester);

      expect(find.text('0 / 6 정답!'), findsOneWidget);
      expect(find.text('하트를 모두 썼어요. 다시 도전해 볼까요?'), findsOneWidget);
      expect(find.text('💪'), findsOneWidget);
      expect(find.textContaining('XP'), findsNothing);
      expect(find.text('틀린 상식은 복습에 추가했어요 🧠'), findsOneWidget);
      for (var i = 0; i < QuizConfig.lives; i++) {
        expect(
          find.text('${qs[i].item.emoji} ${qs[i].item.title}'),
          findsOneWidget,
        );
        expect(progress.isInReview(qs[i].item.id), isTrue);
      }
      expect(progress.quizRounds, 1);
      expect(progress.bestQuizScore, 0);
    });

    testWidgets('a mixed round reports the score and keeps no new best', (
      tester,
    ) async {
      progress.quizRoundFinished(correct: 5); // a better score exists already
      progress.drainNewBadges();
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      await answer(tester, right(qs[0]));
      await goNext(tester);
      await answer(tester, wrong(qs[1]));
      await goNext(tester);
      await answer(tester, right(qs[2]));
      await goNext(tester);
      await answer(tester, right(qs[3]));
      await goNext(tester);
      await answer(tester, right(qs[4]));
      await dismissDialogs(tester);
      await goNext(tester);

      expect(find.text('4 / 5 정답!'), findsOneWidget);
      expect(find.text('잘했어요! 한 번 더 해볼까요?'), findsOneWidget);
      expect(find.text('🎉'), findsOneWidget);
      expect(find.textContaining('새 기록'), findsNothing);
      expect(find.text('🔥 최고 3 콤보'), findsOneWidget);
      expect(progress.bestQuizScore, 5, reason: 'the earlier best stays');
    });

    testWidgets('a result after the daily XP cap explains why there is none', (
      tester,
    ) async {
      for (var i = 0; i < 25; i++) {
        progress.quizAnswer('q$i', correct: true);
      }
      expect(progress.quizXpLeftToday, 0);
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      for (var i = 0; i < qs.length; i++) {
        await answer(tester, right(qs[i]));
        if (i < qs.length - 1) await goNext(tester);
      }
      await dismissDialogs(tester);
      await goNext(tester);

      expect(find.text('✅ 오늘 퀴즈 XP를 다 받았어요'), findsOneWidget);
      expect(find.textContaining('⭐'), findsNothing);
    });

    testWidgets('a level-up pops up during the quiz', (tester) async {
      // 78 XP: one right answer (+5) crosses 80, the start of level 3.
      for (var i = 1; i <= 13; i++) {
        progress.complete('d$i', newToMe: false);
      }
      progress.drainNewBadges();
      expect(progress.xp, 78);
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);

      await answer(tester, right(qs.first));

      expect(find.text('LEVEL UP!'), findsOneWidget);
      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP!'), findsNothing);
    });

    testWidgets('"한 번 더" starts a fresh round', (tester) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);
      for (var i = 0; i < QuizConfig.lives; i++) {
        await answer(tester, wrong(qs[i]));
        if (i < QuizConfig.lives - 1) await goNext(tester);
      }
      await dismissDialogs(tester);
      await goNext(tester);
      expect(find.text('0 / 5 정답!'), findsOneWidget);

      await tester.tap(find.text('🔄 한 번 더'));
      await tester.pumpAndSettle();

      expect(find.text(_prompt), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
      expect(hearts(tester), QuizConfig.lives, reason: 'hearts are restored');
    });

    testWidgets('"홈으로" returns to the home screen', (tester) async {
      final qs = fixedQuestions(5);
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, qs);
      for (var i = 0; i < QuizConfig.lives; i++) {
        await answer(tester, wrong(qs[i]));
        if (i < QuizConfig.lives - 1) await goNext(tester);
      }
      await dismissDialogs(tester);
      await goNext(tester);

      await tester.tap(find.text('🏠 홈으로'));
      await tester.pumpAndSettle();

      expect(find.text('아는척'), findsOneWidget);
      expect(find.text(_prompt), findsNothing);
    });

    testWidgets('the back button leaves a round', (tester) async {
      await pumpApp(tester, progress: progress);
      await openQuiz(tester, fixedQuestions(5));

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text(_prompt), findsNothing);
      expect(
        progress.quizRounds,
        0,
        reason: 'an abandoned round is not counted',
      );
    });
  });

  group('built from what the player learned', () {
    testWidgets('only learned cards are asked about', (tester) async {
      final learned = knowledgeItems
          .where((i) => i.categoryId == 'food')
          .take(6);
      for (final item in learned) {
        progress.complete(item.id, newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      await tester.tap(find.text('퀴즈 챌린지'));
      await tester.pumpAndSettle();

      final asked = <String>{};
      for (var i = 0; i < 6; i++) {
        final onScreen = [
          for (final item in knowledgeItems)
            if (find
                .text(maskTitle(item.content, item.title))
                .evaluate()
                .isNotEmpty)
              item,
        ];
        expect(onScreen, hasLength(1), reason: 'question $i');
        asked.add(onScreen.single.id);
        // Answer correctly so the round is not cut short by running out of
        // hearts: the right option is the title of the card on screen.
        await tester.tap(find.text(onScreen.single.title));
        await tester.pumpAndSettle();
        await dismissDialogs(tester);
        if (i < 5) await goNext(tester);
      }

      expect(asked, learned.map((i) => i.id).toSet());
    });

    testWidgets('with nothing learned there is nothing to ask', (tester) async {
      await pumpApp(tester, progress: progress);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => QuizScreen(random: Random(1))),
      );
      await tester.pumpAndSettle();

      expect(find.text('아직 퀴즈를 만들 상식이 없어요'), findsOneWidget);
      expect(find.text(_prompt), findsNothing);
    });
  });

  group('small phones', () {
    Future<void> sweep(WidgetTester tester, Size screen) async {
      final qs = fixedQuestions(8);
      await pumpApp(tester, progress: progress, size: screen);
      await openQuiz(tester, qs);

      void expectOnScreen(Finder finder, String reason) {
        final rect = tester.getRect(finder);
        expect(
          rect.top >= 0 && rect.bottom <= screen.height,
          isTrue,
          reason: '$reason is off screen ($rect on ${screen.height})',
        );
      }

      for (var i = 0; i < qs.length; i++) {
        for (final option in qs[i].options) {
          expectOnScreen(
            find.text(option.title),
            'option "${option.title}" of $i',
          );
        }
        expect(tester.takeException(), isNull, reason: 'question $i');

        // Alternate right and wrong so every state is laid out.
        await answer(tester, i.isEven ? right(qs[i]) : wrong(qs[i]));
        expect(tester.takeException(), isNull, reason: 'answered $i');
        await dismissDialogs(tester);
        final next = find.text(_next);
        final seeResult = find.text(_seeResult);
        final button = next.evaluate().isNotEmpty ? next : seeResult;
        expectOnScreen(button, 'the next button on $i');
        if (seeResult.evaluate().isNotEmpty) break;
        await tester.tap(button);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('every control stays on a 320x568 screen', (tester) async {
      await sweep(tester, const Size(320, 568));
    });

    testWidgets('every control stays on a 360x640 screen', (tester) async {
      await sweep(tester, const Size(360, 640));
    });

    testWidgets('the result fits a small phone', (tester) async {
      final qs = fixedQuestions(8);
      await pumpApp(tester, progress: progress, size: const Size(320, 568));
      await openQuiz(tester, qs);
      for (var i = 0; i < QuizConfig.lives; i++) {
        await answer(tester, wrong(qs[i]));
        if (i < QuizConfig.lives - 1) await goNext(tester);
      }
      await dismissDialogs(tester);
      await goNext(tester);

      expect(tester.takeException(), isNull);
      for (final label in ['🔄 한 번 더', '🏠 홈으로']) {
        expect(tester.getRect(find.text(label)).bottom, lessThanOrEqualTo(568));
      }
    });
  });
}
