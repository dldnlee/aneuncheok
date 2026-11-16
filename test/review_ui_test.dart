import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/state/progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late DateTime now;
  late ProgressStore progress;

  void advance(int days) {
    now = DateTime(now.year, now.month, now.day + days, 12);
  }

  /// Marks a real card "몰랐어요" yesterday so it is due today.
  void learnYesterday(String id) {
    progress.complete(id, newToMe: true);
  }

  Future<void> openReview(WidgetTester tester, int due) async {
    await tester.tap(find.text('복습할 상식 $due개'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    now = DateTime(2026, 1, 7, 12);
    progress = ProgressStore(clock: () => now);
  });

  final d1 = knowledgeItems.firstWhere((i) => i.id == 'd1');

  group('home', () {
    testWidgets('is hidden when nothing is waiting for review', (tester) async {
      await pumpApp(tester, progress: progress);

      expect(find.textContaining('복습'), findsNothing);
    });

    testWidgets('is hidden when every answer was "알고 있었어요"', (tester) async {
      progress.complete('d1', newToMe: false);
      await pumpApp(tester, progress: progress);

      expect(find.textContaining('복습'), findsNothing);
    });

    testWidgets('says when the next review is if none are due yet', (
      tester,
    ) async {
      learnYesterday('d1');
      await pumpApp(tester, progress: progress);

      expect(find.text('오늘 복습 끝!'), findsOneWidget);
      expect(find.text('다음 복습은 내일이에요'), findsOneWidget);
    });

    testWidgets('counts the cards that are due', (tester) async {
      learnYesterday('d1');
      learnYesterday('d2');
      advance(1);
      await pumpApp(tester, progress: progress);

      expect(find.text('복습할 상식 2개'), findsOneWidget);
    });

    testWidgets('mentions a longer wait in days', (tester) async {
      learnYesterday('d1');
      advance(1);
      progress.review('d1', remembered: true); // now due in 3 days
      await pumpApp(tester, progress: progress);

      expect(find.text('다음 복습은 3일 뒤예요'), findsOneWidget);
    });

    testWidgets('caps a big backlog at one session', (tester) async {
      for (var i = 0; i < ReviewSchedule.sessionLimit + 5; i++) {
        progress.complete('card$i', newToMe: true);
      }
      advance(1);
      await pumpApp(tester, progress: progress);
      final total = ReviewSchedule.sessionLimit + 5;

      expect(find.text('복습할 상식 $total개'), findsOneWidget);
      expect(
        find.text('오늘은 ${ReviewSchedule.sessionLimit}개씩 복습해요'),
        findsOneWidget,
      );
    });
  });

  group('a review session', () {
    Future<void> startWithD1(WidgetTester tester) async {
      learnYesterday('d1');
      progress.drainNewBadges();
      advance(1);
      await pumpApp(tester, progress: progress);
      await openReview(tester, 1);
    }

    testWidgets('hides the answer until it is revealed', (tester) async {
      await startWithD1(tester);

      expect(find.text(d1.title), findsOneWidget);
      expect(find.text('이 상식, 기억나요?'), findsOneWidget);
      expect(find.text(d1.content), findsNothing);
      expect(find.text('👀 내용 확인하기'), findsOneWidget);
      expect(find.text('✅ 기억나요!'), findsNothing);
      expect(find.text('복습'), findsOneWidget, reason: 'top bar label');
      expect(
        find.text('🧠 복습 1/${ProgressStore.reviewSteps}단계'),
        findsOneWidget,
      );
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('tapping the recall card reveals the answer too', (
      tester,
    ) async {
      await startWithD1(tester);

      await tester.tap(find.text('이 상식, 기억나요?'));
      await tester.pumpAndSettle();

      expect(find.text(d1.content), findsOneWidget);
    });

    testWidgets('revealing shows the answer and the rating buttons', (
      tester,
    ) async {
      await startWithD1(tester);

      await tester.tap(find.text('👀 내용 확인하기'));
      await tester.pumpAndSettle();

      expect(find.text(d1.content), findsOneWidget);
      expect(find.text('😵 헷갈려요'), findsOneWidget);
      expect(find.text('✅ 기억나요!'), findsOneWidget);
      expect(find.text('이 상식, 기억나요?'), findsNothing);
      expect(find.text('저장'), findsOneWidget, reason: 'save row appears');
    });

    testWidgets('"기억나요" moves the card up and pays XP', (tester) async {
      await startWithD1(tester);
      final xpBefore = progress.xp;

      await tester.tap(find.text('👀 내용 확인하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('✅ 기억나요!'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('XP  기억났다! 🧠'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(progress.reviewStep('d1'), 2);
      expect(progress.reviewCount, 1);
      expect(progress.xp, greaterThanOrEqualTo(xpBefore + XpRewards.reviewed));
      expect(find.text('3일 뒤에 다시 만나요'), findsOneWidget);
      expect(
        find.text('🧠 복습 2/${ProgressStore.reviewSteps}단계'),
        findsOneWidget,
      );
    });

    testWidgets('"헷갈려요" sends the card back to day one', (tester) async {
      await startWithD1(tester);

      await tester.tap(find.text('👀 내용 확인하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('😵 헷갈려요'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('괜찮아요, 내일 또 만나요 💪'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(progress.reviewStep('d1'), 1);
      expect(progress.reviewCount, 0);
      expect(find.text('내일 다시 만나요'), findsOneWidget);
    });

    testWidgets('a card can only be answered once per session', (tester) async {
      await startWithD1(tester);

      await tester.tap(find.text('👀 내용 확인하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('✅ 기억나요!'));
      await tester.pumpAndSettle();
      final xp = progress.xp;
      await tester.tap(find.text('😵 헷갈려요'));
      await tester.pumpAndSettle();

      expect(progress.reviewStep('d1'), 2, reason: 'the first answer stands');
      expect(progress.xp, xp);
      expect(progress.reviewCount, 1);
    });

    testWidgets('the finish screen summarises the session', (tester) async {
      learnYesterday('d1');
      learnYesterday('d2');
      progress.drainNewBadges();
      advance(1);
      await pumpApp(tester, progress: progress);
      await openReview(tester, 2);
      // The streak bonus for today's first activity levels the player up.
      await dismissDialogs(tester);

      for (final answer in ['✅ 기억나요!', '😵 헷갈려요']) {
        await tester.tap(find.text('👀 내용 확인하기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(answer));
        await tester.pumpAndSettle();
        await dismissDialogs(tester); // e.g. a level-up pop-up
        tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .nextPage(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
        await tester.pumpAndSettle();
      }

      expect(find.text('오늘 복습 끝!'), findsWidgets);
      expect(find.text('1개 기억났어요 · 1개는 내일 다시'), findsOneWidget);
      expect(find.text('🔄 처음부터 다시'), findsNothing);

      await tester.tap(find.text('🏠 홈으로'));
      await tester.pumpAndSettle();
      expect(find.text('오늘 복습 끝!'), findsOneWidget, reason: 'home card');
    });

    testWidgets('only cards that are due are included', (tester) async {
      learnYesterday('d1');
      advance(1);
      progress.complete('d2', newToMe: true); // learned today, not due
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      await openReview(tester, 1);

      expect(find.text('1 / 1'), findsOneWidget);
      expect(find.text(d1.title), findsOneWidget);
    });

    testWidgets('the last step graduates the card', (tester) async {
      progress.complete('d1', newToMe: true);
      for (var i = 0; i < ReviewSchedule.intervals.length - 1; i++) {
        advance(31);
        progress.review('d1', remembered: true);
      }
      progress.drainNewBadges();
      advance(31);
      await pumpApp(tester, progress: progress);
      await openReview(tester, 1);
      expect(
        find.text(
          '🧠 복습 ${ProgressStore.reviewSteps}/${ProgressStore.reviewSteps}단계',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('👀 내용 확인하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('✅ 기억나요!'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('🎓 졸업! 복습을 모두 마쳤어요'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(progress.isGraduated('d1'), isTrue);
      expect(find.text('🎓 졸업!'), findsOneWidget, reason: 'step chip');
    });

    testWidgets('reviewing earns the 복습왕 badge on the tenth success', (
      tester,
    ) async {
      final ids = [for (var i = 1; i <= 10; i++) 'd$i'];
      for (final id in ids) {
        progress.complete(id, newToMe: true);
      }
      progress.drainNewBadges();
      advance(1);
      await pumpApp(tester, progress: progress);
      await openReview(tester, 10);

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('👀 내용 확인하기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('✅ 기억나요!'));
        await tester.pumpAndSettle();
        await dismissDialogs(tester);
        if (i < 9) {
          tester
              .widget<PageView>(find.byType(PageView))
              .controller!
              .nextPage(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
          await tester.pumpAndSettle();
          // The 5th card seen today completes the daily goal and pops a badge.
          await dismissDialogs(tester);
        }
      }

      expect(progress.hasBadge('review_10'), isTrue);
    });
  });

  group('layout', () {
    testWidgets('the home card fits a small phone in both states', (
      tester,
    ) async {
      learnYesterday('d1');
      await pumpApp(tester, progress: progress, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.text('오늘 복습 끝!'), findsOneWidget);

      advance(1);
      progress.save('x'); // nudge listeners so the card re-evaluates
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('복습할 상식 1개'), findsOneWidget);
    });

    testWidgets('every review state fits a small phone', (tester) async {
      for (var i = 1; i <= 6; i++) {
        progress.complete('d$i', newToMe: true);
      }
      progress.drainNewBadges();
      advance(1);
      await pumpApp(tester, progress: progress, size: const Size(320, 568));
      await openReview(tester, 6);

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      for (var i = 0; i < 6; i++) {
        controller.jumpToPage(i);
        await tester.pumpAndSettle();
        await dismissDialogs(tester); // the 5th card completes the daily goal
        expect(tester.takeException(), isNull, reason: 'hidden, card $i');

        expect(
          tester.getRect(find.text('👀 내용 확인하기')).bottom,
          lessThanOrEqualTo(568),
          reason: 'reveal button is off screen on card $i',
        );
        await tester.tap(find.text('👀 내용 확인하기'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'revealed, card $i');
        for (final label in ['😵 헷갈려요', '✅ 기억나요!']) {
          expect(
            tester.getRect(find.text(label)).bottom,
            lessThanOrEqualTo(568),
            reason: '"$label" is off screen on card $i',
          );
        }

        await tester.tap(find.text(i.isEven ? '✅ 기억나요!' : '😵 헷갈려요'));
        await tester.pumpAndSettle();
        await dismissDialogs(tester);
        expect(tester.takeException(), isNull, reason: 'answered, card $i');
      }
    });
  });
}
