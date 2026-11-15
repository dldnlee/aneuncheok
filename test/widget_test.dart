import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/state/progress_store.dart';

import 'test_helpers.dart';

void main() {
  group('home', () {
    testWidgets('shows brand, shuffle button, tabs and every category', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('아는척'), findsOneWidget);
      expect(find.text('랜덤 상식'), findsOneWidget);
      for (final label in ['홈', '랭킹', '나']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final category in categories) {
        expect(find.text(category.name), findsOneWidget);
      }
    });

    testWidgets('shows level, XP, daily goal and per-category progress', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Lv.1  ${levels.first.name}'), findsOneWidget);
      expect(find.text('다음 레벨까지 ${levels[1].minXp} XP'), findsOneWidget);
      expect(find.text('🎯 오늘의 목표'), findsOneWidget);
      final first = getItemsByCategory(categories.first.id).length;
      // Several categories can have the same number of cards.
      expect(find.text('0 / $first 알았어요'), findsWidgets);
    });

    testWidgets('shows the goal as reached once five cards were seen', (
      tester,
    ) async {
      final progress = ProgressStore(clock: () => testNow);
      for (var i = 0; i < ProgressStore.dailyGoal; i++) {
        progress.recordView('seen-$i');
      }
      await pumpApp(tester, progress: progress);

      expect(find.text('🎉 목표 달성!'), findsOneWidget);
      expect(find.text('5/5'), findsOneWidget);
    });

    testWidgets('lays out on a small phone without overflow', (tester) async {
      await pumpApp(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.text('랜덤 상식'), findsOneWidget);
    });

    testWidgets('tapping saved with nothing saved explains how to save', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('❤️'));
      await tester.pump();

      expect(find.textContaining('아직 저장한 상식이 없어요'), findsOneWidget);
    });

    testWidgets('rank teaser shows my place among friends and opens ranking', (
      tester,
    ) async {
      await pumpApp(tester);

      // A brand-new player is behind all four default friends.
      expect(find.text('친구 중 5위'), findsOneWidget);

      await tester.tap(find.text('친구 중 5위'));
      await tester.pumpAndSettle();

      expect(find.text('랭킹 🏆'), findsOneWidget);
    });
  });

  group('feed', () {
    testWidgets('category opens its first card with a counter', (tester) async {
      await pumpApp(tester);
      final items = getItemsByCategory(categories.first.id);

      await openFirstCategory(tester);

      expect(find.text(items.first.title), findsOneWidget);
      expect(find.text('1 / ${items.length}'), findsOneWidget);
    });

    testWidgets('shuffle opens a feed with every item', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('랜덤 상식'));
      await tester.pumpAndSettle();

      expect(find.text('1 / ${knowledgeItems.length}'), findsOneWidget);
    });

    testWidgets('back button returns home', (tester) async {
      await pumpApp(tester);

      await openFirstCategory(tester);
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(find.text('랜덤 상식'), findsOneWidget);
    });

    testWidgets('unseen cards come before ones already answered', (
      tester,
    ) async {
      final items = getItemsByCategory(categories.first.id);
      final progress = ProgressStore(clock: () => testNow);
      progress.complete(items.first.id, newToMe: true);
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);

      await openFirstCategory(tester);

      expect(find.text(items[1].title), findsOneWidget);
      expect(find.text(items.first.title), findsNothing);
    });

    testWidgets('viewing the first card starts the streak', (tester) async {
      final app = await pumpApp(tester);
      expect(app.progress.currentStreak, 0);

      await openFirstCategory(tester);

      expect(app.progress.currentStreak, 1);
      expect(find.text('🔥 1일 연속! 멋져요'), findsOneWidget);
    });

    testWidgets('fifth card of the day shows the goal toast and its badge', (
      tester,
    ) async {
      final progress = ProgressStore(clock: () => testNow);
      for (var i = 0; i < ProgressStore.dailyGoal - 1; i++) {
        progress.recordView('seen-$i');
      }
      await pumpApp(tester, progress: progress);

      await openFirstCategory(tester);

      expect(
        find.text('🎯 오늘 목표 달성! +${XpRewards.dailyGoal} XP'),
        findsOneWidget,
      );
      expect(progress.goalReached, isTrue);
      expect(find.text('NEW BADGE!'), findsOneWidget);
      expect(find.text('목표 달성'), findsOneWidget);
    });

    testWidgets('every card and pop-up fits on a small phone', (tester) async {
      await pumpApp(tester, size: const Size(320, 568));
      await tester.tap(find.text('랜덤 상식'));
      await tester.pumpAndSettle();

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      for (var i = 0; i < knowledgeItems.length; i++) {
        controller.jumpToPage(i);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'overflow on card $i');
      }
    });

    testWidgets('the answer buttons stay on screen on a small phone', (
      tester,
    ) async {
      const screen = Size(320, 568);
      await pumpApp(tester, size: screen);
      await tester.tap(find.text('랜덤 상식'));
      await tester.pumpAndSettle();

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      for (var i = 0; i < knowledgeItems.length; i++) {
        controller.jumpToPage(i);
        await tester.pumpAndSettle();
        await dismissDialogs(tester);
        for (final label in [newToMeLabel, alreadyKnewLabel]) {
          final rect = tester.getRect(find.text(label));
          expect(
            rect.top >= 0 && rect.bottom <= screen.height,
            isTrue,
            reason: '"$label" is off screen on card $i ($rect)',
          );
        }
      }
    });

    testWidgets('scrolling past the last card shows the finish screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstCategory(tester);
      final total = getItemsByCategory(categories.first.id).length;

      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .jumpToPage(total);
      await tester.pumpAndSettle();

      expect(find.text('여기까지 다 봤어요!'), findsOneWidget);
      expect(find.text('$total / $total'), findsOneWidget);

      await tester.tap(find.text('🏠 홈으로'));
      await tester.pumpAndSettle();
      expect(find.text('랜덤 상식'), findsOneWidget);
    });

    testWidgets('finish screen shows the XP earned and level progress', (
      tester,
    ) async {
      await pumpApp(tester);
      await openFirstCategory(tester);
      await tester.tap(find.text(newToMeLabel));
      await tester.pumpAndSettle();
      await dismissDialogs(tester);

      final total = getItemsByCategory(categories.first.id).length;
      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .jumpToPage(total);
      await tester.pumpAndSettle();

      expect(find.text('⭐ 이번에 +${XpRewards.newToMe} XP 얻었어요!'), findsOneWidget);
      expect(find.text('🌱 Lv.1  ${levels.first.name}'), findsOneWidget);
    });
  });

  group('interactions', () {
    testWidgets('"몰랐어요" records the reaction, XP and a first badge', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text(newToMeLabel));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('+${XpRewards.newToMe} XP  새로 알았다! 🌟'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(app.progress.reactionFor(first.id), isTrue);
      expect(app.progress.completedCount, 1);
      expect(app.progress.xp, XpRewards.newToMe);
      expect(find.text('NEW BADGE!'), findsOneWidget);
      expect(find.text('첫걸음'), findsOneWidget);
      expect(find.text('위로 스와이프해서 다음 상식'), findsOneWidget);
    });

    testWidgets('"알고 있었어요" is worth less XP', (tester) async {
      final app = await pumpApp(tester);
      await openFirstCategory(tester);

      await tester.tap(find.text(alreadyKnewLabel));
      await tester.pumpAndSettle();

      expect(app.progress.xp, XpRewards.alreadyKnew);
    });

    testWidgets('can change a reaction without double counting', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text(newToMeLabel));
      await tester.pumpAndSettle();
      await dismissDialogs(tester);
      await tester.tap(find.text(alreadyKnewLabel));
      await tester.pumpAndSettle();

      expect(app.progress.reactionFor(first.id), isFalse);
      expect(app.progress.completedCount, 1);
      expect(app.progress.xp, XpRewards.newToMe);
    });

    testWidgets('save button toggles saved state', (tester) async {
      final app = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(app.progress.isSaved(first.id), isTrue);
      expect(find.text('저장됨'), findsOneWidget);

      await tester.tap(find.text('저장됨'));
      await tester.pumpAndSettle();
      expect(app.progress.isSaved(first.id), isFalse);
    });

    testWidgets('double tapping the card saves it', (tester) async {
      final app = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      final spot = tester.getCenter(find.text(first.title));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(spot);
      await tester.pumpAndSettle();

      expect(app.progress.isSaved(first.id), isTrue);
    });

    testWidgets('saved cards open from the home chip', (tester) async {
      final app = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      app.progress.save(first.id);
      await tester.pump();

      await tester.tap(find.text('❤️'));
      await tester.pumpAndSettle();

      expect(find.text('저장한 상식'), findsOneWidget);
      expect(find.text(first.title), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('copy button copies the card and counts as a share', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final app = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text('복사'));
      await tester.pumpAndSettle();

      expect(copied, contains(first.title));
      expect(find.textContaining('복사했어요'), findsOneWidget);
      expect(app.progress.shares, 1);
    });

    testWidgets('reaching a new level shows the level-up dialog', (
      tester,
    ) async {
      final progress = ProgressStore(clock: () => testNow);
      final reactions = levels[1].minXp ~/ XpRewards.newToMe;
      for (var i = 0; i < reactions - 1; i++) {
        progress.complete('earlier-$i', newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);
      await openFirstCategory(tester);

      await tester.tap(find.text(newToMeLabel));
      await tester.pumpAndSettle();

      expect(find.text('LEVEL UP!'), findsOneWidget);
      expect(find.text(levels[1].name), findsOneWidget);

      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP!'), findsNothing);
    });

    testWidgets('finishing a category cheers and awards its badge', (
      tester,
    ) async {
      final category = categories.first;
      final ids = getItemsByCategory(category.id).map((i) => i.id).toList();
      final progress = ProgressStore(clock: () => testNow);
      for (final id in ids.take(ids.length - 1)) {
        progress.complete(id, newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress);
      await openFirstCategory(tester);

      await tester.tap(find.text(newToMeLabel));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('🏆 ${category.name} 정복! +${XpRewards.categoryMastery} XP'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      // If this reaction also crosses a level, that dialog comes first,
      // then the badge.
      final xpBefore = ids.length - 1;
      final crossesLevel =
          levelForXp(
            xpBefore * XpRewards.newToMe +
                XpRewards.newToMe +
                XpRewards.categoryMastery,
          ) !=
          levelForXp(xpBefore * XpRewards.newToMe);
      if (crossesLevel) {
        expect(find.text('LEVEL UP!'), findsOneWidget);
        await tester.tap(find.text('계속하기'));
        await tester.pumpAndSettle();
      } else {
        expect(find.text('LEVEL UP!'), findsNothing);
      }
      expect(find.text('NEW BADGE!'), findsOneWidget);
      expect(find.text('${category.name} 박사'), findsOneWidget);
      await dismissDialogs(tester);
      expect(progress.hasBadge('master_${category.id}'), isTrue);
    });
  });
}
