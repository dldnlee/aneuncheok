import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/main.dart';
import 'package:aneuncheok/state/progress_store.dart';

const _newToMe = '🤯 몰랐어요!';
const _alreadyKnew = '😎 알고 있었어요';

/// Phone-sized surface (so the lazy category grid is fully built) with
/// "reduce motion" on, so looping animations do not stop pumpAndSettle.
Future<ProgressStore> pumpApp(
  WidgetTester tester, {
  ProgressStore? store,
  Size size = const Size(400, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final s = store ?? ProgressStore(clock: () => DateTime(2026, 1, 1, 9));
  await tester.pumpWidget(MyApp(store: s));
  return s;
}

Future<void> openFirstCategory(WidgetTester tester) async {
  await tester.tap(find.text(categories.first.name));
  await tester.pumpAndSettle();
}

void main() {
  group('home', () {
    testWidgets('shows brand, shuffle button and every category', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('아는척'), findsOneWidget);
      expect(find.text('랜덤 상식'), findsOneWidget);
      for (final category in categories) {
        expect(find.text(category.name), findsOneWidget);
      }
    });

    testWidgets('shows level, daily goal and per-category progress', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Lv.1  ${levels.first.name}'), findsOneWidget);
      expect(find.text('🎯 오늘의 목표'), findsOneWidget);
      final first = getItemsByCategory(categories.first.id).length;
      expect(find.text('0 / $first 알았어요'), findsOneWidget);
    });

    testWidgets('shows the goal as reached once five cards were seen', (
      tester,
    ) async {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      for (var i = 0; i < ProgressStore.dailyGoal; i++) {
        store.recordView('seen-$i');
      }
      await pumpApp(tester, store: store);

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
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      store.complete(items.first.id, newToMe: true);
      await pumpApp(tester, store: store);

      await openFirstCategory(tester);

      expect(find.text(items[1].title), findsOneWidget);
      expect(find.text(items.first.title), findsNothing);
    });

    testWidgets('viewing the first card starts the streak', (tester) async {
      final store = await pumpApp(tester);
      expect(store.currentStreak, 0);

      await openFirstCategory(tester);

      expect(store.currentStreak, 1);
      expect(find.text('🔥 1일 연속! 멋져요'), findsOneWidget);
    });

    testWidgets('fifth card of the day shows the goal toast', (tester) async {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      for (var i = 0; i < ProgressStore.dailyGoal - 1; i++) {
        store.recordView('seen-$i');
      }
      await pumpApp(tester, store: store);

      await openFirstCategory(tester);

      expect(find.text('🎯 오늘 목표 달성! 대단해요'), findsOneWidget);
      expect(store.goalReached, isTrue);
    });

    testWidgets('every card fits on a small phone without overflow', (
      tester,
    ) async {
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
  });

  group('interactions', () {
    testWidgets('"몰랐어요" records the reaction', (tester) async {
      final store = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text(_newToMe));
      await tester.pumpAndSettle();

      expect(store.reactionFor(first.id), isTrue);
      expect(store.completedCount, 1);
      expect(find.text('위로 스와이프해서 다음 상식'), findsOneWidget);
    });

    testWidgets('can change a reaction without double counting', (
      tester,
    ) async {
      final store = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text(_newToMe));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_alreadyKnew));
      await tester.pumpAndSettle();

      expect(store.reactionFor(first.id), isFalse);
      expect(store.completedCount, 1);
    });

    testWidgets('save button toggles saved state', (tester) async {
      final store = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(store.isSaved(first.id), isTrue);
      expect(find.text('저장됨'), findsOneWidget);

      await tester.tap(find.text('저장됨'));
      await tester.pumpAndSettle();
      expect(store.isSaved(first.id), isFalse);
    });

    testWidgets('double tapping the card saves it', (tester) async {
      final store = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      final spot = tester.getCenter(find.text(first.title));
      await tester.tapAt(spot);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tapAt(spot);
      await tester.pumpAndSettle();

      expect(store.isSaved(first.id), isTrue);
    });

    testWidgets('saved cards open from the home chip', (tester) async {
      final store = await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      store.save(first.id);
      await tester.pump();

      await tester.tap(find.text('❤️'));
      await tester.pumpAndSettle();

      expect(find.text('저장한 상식'), findsOneWidget);
      expect(find.text(first.title), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('copy button puts the card on the clipboard', (tester) async {
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
      await pumpApp(tester);
      final first = getItemsByCategory(categories.first.id).first;
      await openFirstCategory(tester);

      await tester.tap(find.text('복사'));
      await tester.pumpAndSettle();

      expect(copied, contains(first.title));
      expect(find.textContaining('복사했어요'), findsOneWidget);
    });

    testWidgets('reaching a new level shows the level-up dialog', (
      tester,
    ) async {
      final store = ProgressStore(clock: () => DateTime(2026, 1, 1));
      final threshold = levels[1].minCompleted;
      for (var i = 0; i < threshold - 1; i++) {
        store.complete('earlier-$i', newToMe: true);
      }
      await pumpApp(tester, store: store);
      await openFirstCategory(tester);

      await tester.tap(find.text(_newToMe));
      await tester.pumpAndSettle();

      expect(find.text('LEVEL UP!'), findsOneWidget);
      expect(find.text(levels[1].name), findsOneWidget);

      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      expect(find.text('LEVEL UP!'), findsNothing);
    });
  });
}
