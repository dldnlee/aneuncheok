import 'dart:math';

import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/main.dart';
import 'package:aneuncheok/social/social_repository.dart';
import 'package:aneuncheok/social/social_store.dart';
import 'package:aneuncheok/state/progress_store.dart';
import 'package:aneuncheok/widgets/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const newToMeLabel = '🤯 몰랐어요!';
const alreadyKnewLabel = '😎 알고 있었어요';

/// A Wednesday, so the simulated friends have a few days of XP.
final testNow = DateTime(2026, 1, 7, 12);

class TestApp {
  const TestApp(this.progress, this.social, this.repository);

  final ProgressStore progress;
  final SocialStore social;
  final SocialRepository repository;
}

/// Pumps the whole app on a phone-sized surface (so lazy lists are fully
/// built) with "reduce motion" on, so looping animations do not stop
/// pumpAndSettle.
Future<TestApp> pumpApp(
  WidgetTester tester, {
  ProgressStore? progress,
  SocialRepository? repository,
  Size size = const Size(400, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final p = progress ?? ProgressStore(clock: () => testNow);
  final repo = repository ?? DemoSocialRepository(clock: () => testNow);
  final social = SocialStore(progress: p, repository: repo, random: Random(1));

  await tester.pumpWidget(MyApp(store: p, social: social));
  // Lets the startup refresh (friends + leaderboard) finish.
  await tester.pumpAndSettle();
  return TestApp(p, social, repo);
}

Future<void> openFirstCategory(WidgetTester tester) async {
  await tester.tap(find.text(categories.first.name));
  await tester.pumpAndSettle();
}

/// Closes level-up and badge pop-ups until none are left.
Future<void> dismissDialogs(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    final ok = find.text('확인');
    final next = find.text('계속하기');
    if (ok.evaluate().isNotEmpty) {
      await tester.tap(ok);
    } else if (next.evaluate().isNotEmpty) {
      await tester.tap(next);
    } else {
      return;
    }
    await tester.pumpAndSettle();
  }
}

/// Taps the bottom-nav tab with this label ('홈', '랭킹' or '나').
///
/// Scoped to pressable widgets so it cannot hit a same-named label elsewhere
/// (e.g. the "나" shown on the podium).
Future<void> openTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(PressableScale),
    matching: find.text(label),
  );
  await tester.tap(tab);
  await tester.pumpAndSettle();
}
