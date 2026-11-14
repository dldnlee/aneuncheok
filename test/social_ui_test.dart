import 'package:aneuncheok/screens/profile_screen.dart';
import 'package:aneuncheok/social/identity.dart';
import 'package:aneuncheok/social/models.dart';
import 'package:aneuncheok/social/social_repository.dart';
import 'package:aneuncheok/state/progress_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Tall enough that the whole profile/ranking list is built.
const _tall = Size(400, 3600);

void main() {
  group('navigation', () {
    testWidgets('switches between home, ranking and profile', (tester) async {
      final app = await pumpApp(tester);
      expect(find.text('랜덤 상식'), findsOneWidget);

      await openTab(tester, '랭킹');
      expect(find.text('랭킹 🏆'), findsOneWidget);
      expect(find.text('랜덤 상식'), findsNothing);

      await openTab(tester, '나');
      expect(find.text(app.social.identity.nickname), findsOneWidget);
      expect(find.text('나의 여정 🗺️'), findsOneWidget);

      await openTab(tester, '홈');
      expect(find.text('랜덤 상식'), findsOneWidget);
    });

    testWidgets('the profile tab shows my avatar', (tester) async {
      final app = await pumpApp(tester);

      expect(find.text(app.social.identity.avatar), findsWidgets);
    });
  });

  group('ranking', () {
    testWidgets('friends board shows me and every friend', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openTab(tester, '랭킹');

      expect(find.textContaining('데모 모드'), findsOneWidget);
      expect(find.text('친구 중 5위'), findsOneWidget);
      for (final friend in await app.repository.friends()) {
        expect(find.text(friend.nickname), findsOneWidget);
      }
      expect(find.text('${app.social.identity.nickname} (나)'), findsOneWidget);
    });

    testWidgets('names the next friend to beat and how much XP it takes', (
      tester,
    ) async {
      final app = await pumpApp(tester);
      await openTab(tester, '랭킹');

      final rival = app.social.rivalAbove!;
      final need = app.social.xpToPass(rival.profile);
      final cards = (need / XpRewards.newToMe).ceil();

      expect(
        find.text(
          '${rival.profile.avatar} ${rival.profile.nickname}님까지 $need XP\n'
          '카드 $cards개면 따라잡아요! 💪',
        ),
        findsOneWidget,
      );
    });

    testWidgets('moves up live as I earn XP', (tester) async {
      final app = await pumpApp(tester);
      await openTab(tester, '랭킹');
      expect(find.text('친구 중 5위'), findsOneWidget);

      for (var i = 0; i < 40; i++) {
        app.progress.complete('c$i', newToMe: true);
      }
      await tester.pump();

      expect(find.text('친구 중 1위'), findsOneWidget);
      expect(find.textContaining('1등이에요'), findsOneWidget);
    });

    testWidgets('global tab shows my place among all players', (tester) async {
      await pumpApp(tester, size: _tall);
      await openTab(tester, '랭킹');

      await tester.tap(find.text('🌍 전체'));
      await tester.pumpAndSettle();

      final players = DemoSocialRepository.playerCount + 1;
      expect(find.text('전체 $players위 / $players명'), findsOneWidget);
      expect(find.textContaining('상위 100%'), findsOneWidget);
    });

    testWidgets('tapping a friend opens a head-to-head comparison', (
      tester,
    ) async {
      final app = await pumpApp(tester, size: _tall);
      await openTab(tester, '랭킹');
      final friend = app.social.friendEntries.first.profile;

      await tester.tap(find.text(friend.nickname));
      await tester.pumpAndSettle();

      for (final label in ['이번 주 XP', '총 XP', '레벨', '연속 접속', '알게 된 상식', '배지']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('조금만 더 힘내요! 💪'), findsOneWidget);
      expect(find.text('친구 삭제'), findsOneWidget);
    });

    testWidgets('the comparison says so when I am ahead', (tester) async {
      final progress = ProgressStore(clock: () => testNow);
      for (var i = 0; i < 90; i++) {
        progress.complete('c$i', newToMe: true);
      }
      progress.drainNewBadges();
      final app = await pumpApp(tester, progress: progress, size: _tall);
      await openTab(tester, '랭킹');
      final friend = (await app.repository.friends()).first;

      await tester.tap(find.text(friend.nickname));
      await tester.pumpAndSettle();

      expect(find.text('이기고 있어요! 🔥'), findsOneWidget);
    });

    testWidgets('a friend can be removed from the comparison', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openTab(tester, '랭킹');
      final friend = app.social.friendEntries.first.profile;

      await tester.tap(find.text(friend.nickname));
      await tester.pumpAndSettle();
      await tester.tap(find.text('친구 삭제'));
      await tester.pumpAndSettle();

      expect(find.text(friend.nickname), findsNothing);
      expect(app.social.friendEntries, hasLength(4));
    });

    testWidgets('a global player can be added as a friend', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openTab(tester, '랭킹');
      await tester.tap(find.text('🌍 전체'));
      await tester.pumpAndSettle();
      final friendCodes = (await app.repository.friends()).map((f) => f.code);
      final stranger = app.social.globalEntries.firstWhere(
        (e) => !e.isMe && !friendCodes.contains(e.profile.code),
      );

      await tester.tap(find.text(stranger.profile.nickname));
      await tester.pumpAndSettle();
      await tester.tap(find.text('👫 친구 추가'));
      await tester.pumpAndSettle();

      expect(
        app.social.friendEntries.map((e) => e.profile.code),
        contains(stranger.profile.code),
      );
    });

    testWidgets('empty state invites me to add a friend', (tester) async {
      await pumpApp(tester, repository: _NoFriends(), size: _tall);

      // Nothing to compare with yet, so home stays quiet.
      expect(find.textContaining('친구 중'), findsNothing);

      await openTab(tester, '랭킹');
      expect(find.text('아직 친구가 없어요'), findsOneWidget);
      expect(find.text('➕ 친구 추가'), findsOneWidget);
    });

    testWidgets('a failing backend shows an error with a working retry', (
      tester,
    ) async {
      final repo = _Flaky();
      await pumpApp(tester, repository: repo);
      await openTab(tester, '랭킹');

      expect(find.text('랭킹을 불러오지 못했어요'), findsOneWidget);

      repo.working = true;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('랭킹을 불러오지 못했어요'), findsNothing);
      expect(find.text('친구 중 5위'), findsOneWidget);
    });
  });

  group('add friend', () {
    Future<void> openSheet(WidgetTester tester) async {
      await openTab(tester, '랭킹');
      await tester.tap(find.text('➕ 친구 추가'));
      await tester.pumpAndSettle();
    }

    Future<void> submit(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.tap(find.text('추가하기'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows my code so I can invite friends', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openSheet(tester);

      expect(find.text('내 친구 코드'), findsOneWidget);
      expect(find.text(formatCode(app.social.identity.code)), findsOneWidget);
    });

    testWidgets('adds a friend from a demo code chip', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openSheet(tester);
      final sample = app.social.sampleCodes.first;

      await tester.tap(find.text(formatCode(sample)));
      await tester.pump();
      await tester.tap(find.text('추가하기'));
      await tester.pumpAndSettle();

      expect(find.textContaining('친구로 추가했어요'), findsOneWidget);
      expect(app.social.friendEntries, hasLength(6));
      expect(find.text('내 친구 코드'), findsNothing, reason: 'sheet closed');
    });

    testWidgets('typed codes are upper-cased and accepted', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openSheet(tester);

      await submit(tester, app.social.sampleCodes.first.toLowerCase());

      expect(app.social.friendEntries, hasLength(6));
    });

    testWidgets('explains each kind of mistake', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openSheet(tester);
      final existing = (await app.repository.friends()).first.code;

      await submit(tester, 'abc');
      expect(find.text('코드는 영문·숫자 6자리예요'), findsOneWidget);

      await submit(tester, app.social.identity.code);
      expect(find.textContaining('내 코드예요'), findsOneWidget);

      await submit(tester, 'ZZZZZZ');
      expect(find.text('이 코드를 가진 친구를 찾지 못했어요'), findsOneWidget);

      await submit(tester, existing);
      expect(find.text('이미 친구예요!'), findsOneWidget);

      expect(app.social.friendEntries, hasLength(5), reason: 'nothing added');
    });

    testWidgets('the invite button copies a message with my code', (
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
      final app = await pumpApp(tester, size: _tall);
      await openSheet(tester);

      await tester.tap(find.text('초대 복사'));
      await tester.pumpAndSettle();

      expect(copied, contains(formatCode(app.social.identity.code)));
      expect(find.textContaining('초대 메시지를 복사했어요'), findsOneWidget);
    });
  });

  group('profile', () {
    testWidgets('shows my level, XP and stats', (tester) async {
      final progress = ProgressStore(clock: () => testNow);
      for (var i = 0; i < 4; i++) {
        progress.complete('c$i', newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress, size: _tall);
      await openTab(tester, '나');

      // 40 XP is already past the first threshold, so I am on level 2.
      expect(progress.levelNumber, 2);
      expect(
        find.text(
          '${progress.level.emoji} Lv.${progress.levelNumber}  ${progress.level.name}',
        ),
        findsOneWidget,
      );
      expect(find.text('${progress.xp} XP'), findsOneWidget);
      expect(
        find.text('다음 레벨까지 ${progress.nextLevel!.minXp - progress.xp} XP'),
        findsWidgets,
      );
      expect(find.text('4 / 65'), findsOneWidget);
      expect(find.text('알게 된 상식'), findsOneWidget);
    });

    testWidgets('the journey marks done, current and locked levels', (
      tester,
    ) async {
      final progress = ProgressStore(clock: () => testNow);
      // 80 XP = level 3.
      for (var i = 0; i < 8; i++) {
        progress.complete('c$i', newToMe: true);
      }
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress, size: _tall);
      await openTab(tester, '나');

      for (var i = 0; i < levels.length; i++) {
        expect(find.text('Lv.${i + 1}  ${levels[i].name}'), findsOneWidget);
      }
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.text('현재'), findsOneWidget);
      expect(find.text('🔒'), findsNWidgets(levels.length - 3));
    });

    testWidgets('locked badges show their progress; tapping explains', (
      tester,
    ) async {
      await pumpApp(tester, size: _tall);
      await openTab(tester, '나');

      // Shown in the section heading and in the stats tile.
      expect(find.text('0 / 17'), findsNWidgets(2));

      await tester.tap(find.text('첫걸음'));
      await tester.pumpAndSettle();

      expect(find.text('아직 잠겨 있어요'), findsOneWidget);
      expect(find.text('첫 상식에 반응하기'), findsOneWidget);
      expect(find.text('진행도 0 / 1'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('아직 잠겨 있어요'), findsNothing);
    });

    testWidgets('earned badges are marked as such', (tester) async {
      final progress = ProgressStore(clock: () => testNow);
      progress.complete('a', newToMe: true);
      progress.drainNewBadges();
      await pumpApp(tester, progress: progress, size: _tall);
      await openTab(tester, '나');

      expect(find.text('1 / 17'), findsNWidgets(2));
      expect(find.text('획득!'), findsOneWidget);

      await tester.tap(find.text('첫걸음'));
      await tester.pumpAndSettle();
      expect(find.text('획득한 배지'), findsOneWidget);
    });

    testWidgets('the identity editor changes nickname and avatar', (
      tester,
    ) async {
      final app = await pumpApp(tester, size: _tall);
      await openTab(tester, '나');
      final code = app.social.identity.code;
      // Always pick something different from the current look, so the
      // emoji appears once in the picker and the change is real.
      final animal =
          animals[(app.social.identity.animalIndex + 3) % animals.length];
      final adjective =
          adjectives[(app.social.identity.adjectiveIndex + 3) %
              adjectives.length];

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();
      expect(find.text('캐릭터'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(IdentitySheet),
          matching: find.text(animal.emoji),
        ),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, adjective));
      await tester.pumpAndSettle();

      expect(app.social.identity.nickname, '$adjective ${animal.name}');
      expect(app.social.identity.code, code, reason: 'the code never changes');

      await tester.tap(find.text('완료'));
      await tester.pumpAndSettle();
      expect(find.text('$adjective ${animal.name}'), findsOneWidget);
    });

    testWidgets('random reroll keeps the friend code', (tester) async {
      final app = await pumpApp(tester, size: _tall);
      await openTab(tester, '나');
      final code = app.social.identity.code;

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🎲 랜덤'));
      await tester.pumpAndSettle();

      expect(app.social.identity.code, code);
    });

    testWidgets('lays out on a small phone without overflow', (tester) async {
      await pumpApp(tester, size: const Size(320, 568));
      await openTab(tester, '나');
      await tester.drag(find.byType(ListView), const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await openTab(tester, '랭킹');
      expect(tester.takeException(), isNull);
    });
  });
}

/// A backend where nobody has any friends yet.
class _NoFriends extends DemoSocialRepository {
  _NoFriends() : super(clock: () => testNow);

  @override
  Future<List<PublicProfile>> friends() async => const [];
}

/// A backend that fails until [working] is switched on.
class _Flaky extends DemoSocialRepository {
  _Flaky() : super(clock: () => testNow);

  bool working = false;

  @override
  Future<List<PublicProfile>> friends() {
    if (!working) throw Exception('offline');
    return super.friends();
  }
}
