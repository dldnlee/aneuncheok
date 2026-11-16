import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/progress_store.dart';
import 'identity.dart';
import 'models.dart';
import 'social_repository.dart';

/// Who I am, who my friends are and how I rank.
///
/// My own row is always built from the live [ProgressStore], so rankings
/// move the moment I earn XP - only other players need a [refresh].
class SocialStore extends ChangeNotifier {
  SocialStore({
    required this.progress,
    required this.repository,
    SharedPreferences? prefs,
    Random? random,
  }) : _prefs = prefs,
       _random = random ?? Random() {
    _identity = _loadIdentity();
    progress.addListener(notifyListeners);
  }

  static const _identityKey = 'identity_v1';

  /// Players shown on the global board.
  static const globalLimit = 20;

  final ProgressStore progress;
  final SocialRepository repository;
  final SharedPreferences? _prefs;
  final Random _random;

  late Identity _identity;
  List<PublicProfile> _friends = const [];
  GlobalBoard? _global;
  bool _loading = false;
  bool _failed = false;
  bool _disposed = false;

  // ---- identity -------------------------------------------------------

  Identity get identity => _identity;
  String get inviteText =>
      '나랑 아는척 상식 대결하자! 😎\n내 친구 코드: ${formatCode(_identity.code)}';

  PublicProfile get me => PublicProfile(
    code: _identity.code,
    nickname: _identity.nickname,
    avatar: _identity.avatar,
    totalXp: progress.xp,
    weeklyXp: progress.weeklyXp,
    streak: progress.currentStreak,
    completed: progress.completedCount,
    badgeCount: progress.badgeCount,
  );

  void updateIdentity({int? adjectiveIndex, int? animalIndex}) {
    _identity = _identity.copyWith(
      adjectiveIndex: adjectiveIndex,
      animalIndex: animalIndex,
    );
    _saveIdentity();
    notifyListeners();
    publishMine();
  }

  /// Picks a new random nickname and avatar. The friend code never changes.
  void rerollIdentity() => updateIdentity(
    adjectiveIndex: _random.nextInt(adjectives.length),
    animalIndex: _random.nextInt(animals.length),
  );

  // ---- leaderboards ---------------------------------------------------

  bool get isDemo => repository.isDemo;
  bool get loading => _loading;
  bool get failed => _failed;
  bool get loaded => _global != null;
  bool get hasFriends => _friends.isNotEmpty;
  List<String> get sampleCodes => repository.sampleCodes;

  /// Me and my friends, ranked by weekly XP.
  List<LeaderboardEntry> get friendEntries => _rank([..._friends, me]);

  /// The global top list with me merged in at my position.
  List<LeaderboardEntry> get globalEntries {
    final board = _global;
    final mine = me;
    if (board == null) {
      return [LeaderboardEntry(profile: mine, rank: 1, isMe: true)];
    }

    final entries = _rank([...board.top, mine]);
    final myIndex = entries.indexWhere((e) => e.isMe);
    if (myIndex == entries.length - 1) {
      // Behind everyone shown: the real rank comes from the server.
      final rank = max(entries.length, board.playersAheadOfMe + 1);
      entries[myIndex] = LeaderboardEntry(
        profile: mine,
        rank: rank,
        isMe: true,
      );
    }
    return entries;
  }

  int get globalPlayers => (_global?.totalPlayers ?? 0) + 1;

  LeaderboardEntry? get myFriendEntry =>
      friendEntries.firstWhere((e) => e.isMe);

  /// My place among friends, or null when I have none yet.
  int? get friendRank => hasFriends ? myFriendEntry!.rank : null;

  /// The friend ranked just above me, or null when I am first.
  LeaderboardEntry? get rivalAbove {
    final entries = friendEntries;
    final i = entries.indexWhere((e) => e.isMe);
    return i > 0 ? entries[i - 1] : null;
  }

  /// Weekly XP I still need to overtake [other].
  int xpToPass(PublicProfile other) =>
      max(0, other.weeklyXp - progress.weeklyXp) + 1;

  List<LeaderboardEntry> _rank(List<PublicProfile> everyone) {
    final sorted = [...everyone]..sort(compareByWeeklyXp);
    return [
      for (var i = 0; i < sorted.length; i++)
        LeaderboardEntry(
          profile: sorted[i],
          rank: i + 1,
          isMe: sorted[i].code == _identity.code,
        ),
    ];
  }

  // ---- actions --------------------------------------------------------

  /// Publishes my stats and reloads friends and the global board.
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _failed = false;
    _notify();
    try {
      await repository.publish(me);
      final friends = await repository.friends();
      final global = await repository.globalBoard(me, limit: globalLimit);
      _friends = friends;
      _global = global;
    } catch (_) {
      _failed = true;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Fire-and-forget upload of my stats (e.g. after a study session).
  Future<void> publishMine() async {
    try {
      await repository.publish(me);
    } catch (_) {
      // Not worth interrupting the player; the next refresh retries.
    }
  }

  Future<AddFriendResult> addFriend(String input) async {
    final code = normalizeCode(input);
    if (code == null) return AddFriendResult.invalidCode;
    final result = await repository.addFriend(code, myCode: _identity.code);
    if (result == AddFriendResult.added) {
      _friends = await repository.friends();
      _notify();
    }
    return result;
  }

  Future<void> removeFriend(String code) async {
    await repository.removeFriend(code);
    _friends = await repository.friends();
    _notify();
  }

  // ---- internals ------------------------------------------------------

  Identity _loadIdentity() {
    final raw = _prefs?.getString(_identityKey);
    if (raw != null) {
      try {
        final parsed = Identity.tryFromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (parsed != null) return parsed;
      } catch (_) {
        // Fall through and create a fresh identity.
      }
    }
    final fresh = generateIdentity(_random);
    _prefs?.setString(_identityKey, jsonEncode(fresh.toJson()));
    return fresh;
  }

  void _saveIdentity() {
    _prefs?.setString(_identityKey, jsonEncode(_identity.toJson()));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    progress.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Makes the [SocialStore] available below [MaterialApp].
class SocialScope extends InheritedNotifier<SocialStore> {
  const SocialScope({
    super.key,
    required SocialStore store,
    required super.child,
  }) : super(notifier: store);

  static SocialStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SocialScope>();
    assert(scope != null, 'No SocialScope found in context');
    return scope!.notifier!;
  }

  static SocialStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SocialScope>();
    assert(scope != null, 'No SocialScope found in context');
    return scope!.notifier!;
  }
}
