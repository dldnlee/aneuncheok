import 'dart:math';

import 'package:aneuncheok/social/identity.dart';
import 'package:aneuncheok/social/models.dart';
import 'package:aneuncheok/social/social_repository.dart';
import 'package:aneuncheok/social/social_store.dart';
import 'package:aneuncheok/state/progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wednesday, so Mon-Wed of simulated XP has accrued.
final _wed = DateTime(2026, 1, 7, 12);

PublicProfile profile(
  String code, {
  int weekly = 0,
  int total = 0,
  String nickname = 'x',
}) => PublicProfile(
  code: code,
  nickname: nickname,
  avatar: '🐼',
  totalXp: total,
  weeklyXp: weekly,
  streak: 0,
  completed: 0,
  badgeCount: 0,
);

void main() {
  group('identity', () {
    test('normalizeCode accepts any case, spaces and dashes', () {
      expect(normalizeCode('k7qw3x'), 'K7QW3X');
      expect(normalizeCode(' K7Q-W3X '), 'K7QW3X');
      expect(normalizeCode('K7Q W3X'), 'K7QW3X');
    });

    test('normalizeCode rejects wrong length and look-alike characters', () {
      expect(normalizeCode(''), isNull);
      expect(normalizeCode('ABC'), isNull);
      expect(normalizeCode('ABCDEFG'), isNull);
      // 0, O, 1 and I are excluded from the alphabet.
      expect(normalizeCode('ABCDE0'), isNull);
      expect(normalizeCode('ABCDEO'), isNull);
      expect(normalizeCode('ABCDE1'), isNull);
      expect(normalizeCode('ABCDEI'), isNull);
      expect(normalizeCode('ABC!EF'), isNull);
    });

    test('formatCode inserts a dash and leaves other input alone', () {
      expect(formatCode('K7QW3X'), 'K7Q-W3X');
      expect(formatCode('ABC'), 'ABC');
    });

    test('generated identities are valid and round-trip through JSON', () {
      final random = Random(1);
      for (var i = 0; i < 50; i++) {
        final id = generateIdentity(random);
        expect(normalizeCode(id.code), id.code);
        expect(id.nickname, '${id.adjective} ${id.animalName}');

        final back = Identity.tryFromJson(id.toJson());
        expect(back, isNotNull);
        expect(back!.nickname, id.nickname);
        expect(back.code, id.code);
      }
    });

    test('tryFromJson rejects malformed or out-of-range data', () {
      expect(Identity.tryFromJson({}), isNull);
      expect(
        Identity.tryFromJson({'adjective': 999, 'animal': 0, 'code': 'ABCDEF'}),
        isNull,
      );
      expect(
        Identity.tryFromJson({'adjective': 0, 'animal': -1, 'code': 'ABCDEF'}),
        isNull,
      );
      expect(
        Identity.tryFromJson({'adjective': 0, 'animal': 0, 'code': 'bad'}),
        isNull,
      );
      expect(
        Identity.tryFromJson({'adjective': '0', 'animal': 0, 'code': 'ABCDEF'}),
        isNull,
      );
    });

    test('copyWith keeps the friend code', () {
      final id = generateIdentity(Random(2));
      final changed = id.copyWith(adjectiveIndex: 0, animalIndex: 0);
      expect(changed.code, id.code);
    });
  });

  group('ordering', () {
    test('more weekly XP first, then total XP, then code', () {
      final list = [
        profile('C', weekly: 10, total: 5),
        profile('A', weekly: 10, total: 5),
        profile('B', weekly: 10, total: 50),
        profile('D', weekly: 99),
      ]..sort(compareByWeeklyXp);

      expect(list.map((p) => p.code), ['D', 'B', 'A', 'C']);
    });

    test('profiles round-trip through JSON', () {
      final p = profile('ABCDEF', weekly: 3, total: 9, nickname: '용감한 판다');
      final back = PublicProfile.fromJson(p.toJson());
      expect(back.nickname, '용감한 판다');
      expect(back.weeklyXp, 3);
      expect(back.totalXp, 9);
    });
  });

  group('demo repository', () {
    test('starts with four friends and 30 simulated players', () async {
      final repo = DemoSocialRepository(clock: () => _wed);
      expect(repo.isDemo, isTrue);
      expect((await repo.friends()), hasLength(4));

      final board = await repo.globalBoard(profile('ME0000'));
      expect(board.totalPlayers, DemoSocialRepository.playerCount);
      expect(board.top, hasLength(20));
    });

    test(
      'is deterministic for the same day and changes the next day',
      () async {
        final a = await DemoSocialRepository(clock: () => _wed).friends();
        final b = await DemoSocialRepository(clock: () => _wed).friends();
        expect(
          a.map((p) => '${p.code}:${p.weeklyXp}'),
          b.map((p) => '${p.code}:${p.weeklyXp}'),
        );

        final next = await DemoSocialRepository(
          clock: () => _wed.add(const Duration(days: 1)),
        ).friends();
        expect(
          next.map((p) => p.weeklyXp).toList(),
          isNot(a.map((p) => p.weeklyXp).toList()),
        );
      },
    );

    test('weekly XP resets on Monday and grows through the week', () async {
      final monday = DateTime(2026, 1, 5, 12);
      final sunday = DateTime(2026, 1, 11, 12);
      final early = await DemoSocialRepository(clock: () => monday).friends();
      final late = await DemoSocialRepository(clock: () => sunday).friends();

      for (var i = 0; i < early.length; i++) {
        expect(late[i].weeklyXp, greaterThan(early[i].weeklyXp));
        expect(late[i].totalXp, greaterThan(early[i].totalXp));
      }
    });

    test('the global board is sorted best-first without duplicates', () async {
      final repo = DemoSocialRepository(clock: () => _wed);
      final board = await repo.globalBoard(profile('ME0000'), limit: 30);

      final sorted = [...board.top]..sort(compareByWeeklyXp);
      expect(board.top.map((p) => p.code), sorted.map((p) => p.code));
      expect(board.top.map((p) => p.code).toSet(), hasLength(30));
    });

    test('playersAheadOfMe reflects my weekly XP', () async {
      final repo = DemoSocialRepository(clock: () => _wed);

      final nobody = await repo.globalBoard(profile('ME0000'));
      expect(nobody.playersAheadOfMe, 30);

      final champion = await repo.globalBoard(
        profile('ME0000', weekly: 1000000),
      );
      expect(champion.playersAheadOfMe, 0);
    });

    test('addFriend reports every outcome', () async {
      final repo = DemoSocialRepository(clock: () => _wed);
      final sample = repo.sampleCodes.first;

      expect(
        await repo.addFriend('nope', myCode: 'MYCODE'),
        AddFriendResult.invalidCode,
      );
      expect(
        await repo.addFriend('ABCDEF', myCode: 'ABCDEF'),
        AddFriendResult.selfCode,
      );
      expect(
        await repo.addFriend('ZZZZZZ', myCode: 'MYCODE'),
        AddFriendResult.notFound,
      );
      expect(
        await repo.addFriend(sample.toLowerCase(), myCode: 'MYCODE'),
        AddFriendResult.added,
      );
      expect(
        await repo.addFriend(sample, myCode: 'MYCODE'),
        AddFriendResult.alreadyFriends,
      );
      expect(await repo.friends(), hasLength(5));
      expect(repo.sampleCodes, isNot(contains(sample)));
    });

    test('removeFriend removes and tolerates unknown codes', () async {
      final repo = DemoSocialRepository(clock: () => _wed);
      final first = (await repo.friends()).first;

      await repo.removeFriend(first.code);
      await repo.removeFriend('UNKNOWN');

      expect(await repo.friends(), hasLength(3));
    });

    test('friends persist across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = DemoSocialRepository(prefs: prefs, clock: () => _wed);
      final added = first.sampleCodes.first;
      await first.addFriend(added, myCode: 'MYCODE');
      await first.removeFriend((await first.friends()).first.code);

      final second = DemoSocialRepository(prefs: prefs, clock: () => _wed);

      expect(
        (await second.friends()).map((p) => p.code),
        (await first.friends()).map((p) => p.code),
      );
      expect((await second.friends()).map((p) => p.code), contains(added));
    });
  });

  group('social store', () {
    late ProgressStore progress;
    late SocialStore social;

    setUp(() {
      progress = ProgressStore(clock: () => _wed);
      social = SocialStore(
        progress: progress,
        repository: DemoSocialRepository(clock: () => _wed),
        random: Random(3),
      );
    });

    tearDown(() => social.dispose());

    test('is empty before the first refresh', () {
      expect(social.loaded, isFalse);
      expect(social.hasFriends, isFalse);
      expect(social.friendRank, isNull);
      expect(social.globalEntries.single.isMe, isTrue);
    });

    test('refresh loads friends and the global board', () async {
      await social.refresh();

      expect(social.loaded, isTrue);
      expect(social.loading, isFalse);
      expect(social.failed, isFalse);
      expect(social.hasFriends, isTrue);
      expect(social.friendEntries, hasLength(5), reason: '4 friends + me');
      expect(social.friendEntries.where((e) => e.isMe), hasLength(1));
    });

    test('ranks are 1..n by weekly XP with me included', () async {
      await social.refresh();
      final entries = social.friendEntries;

      expect(entries.map((e) => e.rank), [1, 2, 3, 4, 5]);
      for (var i = 1; i < entries.length; i++) {
        expect(
          entries[i - 1].profile.weeklyXp,
          greaterThanOrEqualTo(entries[i].profile.weeklyXp),
        );
      }
    });

    test('earning XP moves me up without another refresh', () async {
      await social.refresh();
      final before = social.friendRank!;
      expect(before, 5, reason: 'a brand-new player is last');

      for (var i = 0; i < 40; i++) {
        progress.complete('c$i', newToMe: true);
      }

      expect(social.friendRank, lessThan(before));
      expect(social.me.weeklyXp, progress.weeklyXp);
      expect(social.me.totalXp, progress.xp);
    });

    test('rivalAbove and xpToPass tell me what to beat', () async {
      await social.refresh();
      final rival = social.rivalAbove!;
      expect(rival.rank, social.friendRank! - 1);

      final needed = social.xpToPass(rival.profile);
      expect(needed, rival.profile.weeklyXp - progress.weeklyXp + 1);

      int rankOf(String code) =>
          social.friendEntries.firstWhere((e) => e.profile.code == code).rank;
      bool rivalStillAhead() => rankOf(rival.profile.code) < social.friendRank!;

      // Until I have earned xpToPass, the rival must still be ahead...
      var xp = 0;
      var i = 0;
      while (xp < needed) {
        expect(rivalStillAhead(), isTrue, reason: 'passed early at $xp XP');
        xp += progress.complete('p$i', newToMe: true).xpGained;
        i++;
      }
      // ...and as soon as I have, they are behind me.
      expect(rivalStillAhead(), isFalse);
    });

    test('the leader has no rival above', () async {
      await social.refresh();
      for (var i = 0; i < 90; i++) {
        progress.complete('c$i', newToMe: true);
      }
      expect(social.friendRank, 1);
      expect(social.rivalAbove, isNull);
    });

    test(
      'behind the whole global top list my rank comes from the server',
      () async {
        await social.refresh();
        final entries = social.globalEntries;

        expect(entries.last.isMe, isTrue);
        expect(entries, hasLength(SocialStore.globalLimit + 1));
        expect(entries.last.rank, DemoSocialRepository.playerCount + 1);
        expect(social.globalPlayers, DemoSocialRepository.playerCount + 1);
      },
    );

    test('inside the top list I am merged in at my position', () async {
      await social.refresh();
      for (var i = 0; i < 90; i++) {
        progress.complete('c$i', newToMe: true);
      }

      final entries = social.globalEntries;

      expect(entries.first.isMe, isTrue);
      expect(entries.first.rank, 1);
      expect(
        entries.map((e) => e.rank),
        List.generate(entries.length, (i) => i + 1),
      );
    });

    test('addFriend validates input, then adds and refreshes', () async {
      await social.refresh();

      expect(await social.addFriend('bad'), AddFriendResult.invalidCode);
      expect(
        await social.addFriend(social.identity.code),
        AddFriendResult.selfCode,
      );

      final code = social.sampleCodes.first;
      expect(await social.addFriend(code), AddFriendResult.added);
      expect(social.friendEntries, hasLength(6));
      expect(await social.addFriend(code), AddFriendResult.alreadyFriends);
    });

    test('removeFriend updates the list', () async {
      await social.refresh();
      final friend = social.friendEntries.firstWhere((e) => !e.isMe);

      await social.removeFriend(friend.profile.code);

      expect(social.friendEntries, hasLength(4));
      expect(
        social.friendEntries.map((e) => e.profile.code),
        isNot(contains(friend.profile.code)),
      );
    });

    test('notifies listeners when my own progress changes', () {
      var notified = 0;
      social.addListener(() => notified++);

      progress.complete('a', newToMe: true);

      expect(notified, greaterThan(0));
    });

    test('invite text contains the formatted friend code', () {
      expect(social.inviteText, contains(formatCode(social.identity.code)));
    });
  });

  group('social store identity', () {
    test('is created once, persisted and reused', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = DemoSocialRepository(clock: () => _wed);

      final first = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: repo,
        prefs: prefs,
        random: Random(10),
      );
      final second = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: repo,
        prefs: prefs,
        random: Random(99),
      );

      expect(second.identity.code, first.identity.code);
      expect(second.identity.nickname, first.identity.nickname);
      first.dispose();
      second.dispose();
    });

    test('updateIdentity keeps the code and survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = DemoSocialRepository(clock: () => _wed);
      final store = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: repo,
        prefs: prefs,
        random: Random(4),
      );
      final code = store.identity.code;

      store.updateIdentity(adjectiveIndex: 2, animalIndex: 5);
      await Future<void>.delayed(Duration.zero);

      final reopened = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: repo,
        prefs: prefs,
      );
      expect(reopened.identity.code, code);
      expect(reopened.identity.adjectiveIndex, 2);
      expect(reopened.identity.animalIndex, 5);
      store.dispose();
      reopened.dispose();
    });

    test('rerollIdentity changes the look but never the code', () {
      final store = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: DemoSocialRepository(clock: () => _wed),
        random: Random(5),
      );
      final code = store.identity.code;
      final looks = <String>{store.identity.nickname};
      for (var i = 0; i < 10; i++) {
        store.rerollIdentity();
        looks.add(store.identity.nickname);
        expect(store.identity.code, code);
      }
      expect(looks.length, greaterThan(1));
      store.dispose();
    });

    test('a corrupt saved identity is replaced', () async {
      SharedPreferences.setMockInitialValues({'identity_v1': '{"nope":1}'});
      final prefs = await SharedPreferences.getInstance();

      final store = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: DemoSocialRepository(clock: () => _wed),
        prefs: prefs,
        random: Random(6),
      );

      expect(normalizeCode(store.identity.code), store.identity.code);
      store.dispose();
    });
  });

  group('failure handling', () {
    test('a failing backend sets failed instead of throwing', () async {
      final store = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: _BrokenRepository(),
        random: Random(7),
      );

      await store.refresh();

      expect(store.failed, isTrue);
      expect(store.loading, isFalse);
      expect(store.loaded, isFalse);
      store.dispose();
    });

    test('a later refresh recovers', () async {
      final repo = _FlakyRepository(_wed);
      final store = SocialStore(
        progress: ProgressStore(clock: () => _wed),
        repository: repo,
        random: Random(8),
      );

      await store.refresh();
      expect(store.failed, isTrue);

      repo.working = true;
      await store.refresh();
      expect(store.failed, isFalse);
      expect(store.loaded, isTrue);
      store.dispose();
    });
  });
}

class _BrokenRepository extends DemoSocialRepository {
  _BrokenRepository() : super(clock: () => _wed);

  @override
  Future<List<PublicProfile>> friends() => throw Exception('offline');
}

class _FlakyRepository extends DemoSocialRepository {
  _FlakyRepository(DateTime now) : super(clock: () => now);

  bool working = false;

  @override
  Future<GlobalBoard> globalBoard(PublicProfile me, {int limit = 20}) {
    if (!working) throw Exception('offline');
    return super.globalBoard(me, limit: limit);
  }
}
