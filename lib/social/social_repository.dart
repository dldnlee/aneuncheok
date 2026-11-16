import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../state/badges.dart';
import 'identity.dart';
import 'models.dart';

/// Where friends and leaderboards come from.
///
/// The app only talks to this interface. [DemoSocialRepository] simulates
/// players locally; to go live, implement this against a real backend
/// (e.g. Firebase or Supabase) and pass it to `MyApp` - no UI changes needed.
abstract class SocialRepository {
  /// True when the data is simulated. The UI shows a banner in this case so
  /// nobody mistakes simulated players for real ones.
  bool get isDemo;

  /// Friend codes worth trying out. Only meaningful for demo repositories.
  List<String> get sampleCodes => const [];

  /// Uploads my current public stats so friends can see them.
  Future<void> publish(PublicProfile me);

  /// Current stats of everyone I added as a friend.
  Future<List<PublicProfile>> friends();

  /// Top players this week, plus where [me] stands.
  Future<GlobalBoard> globalBoard(PublicProfile me, {int limit = 20});

  Future<AddFriendResult> addFriend(String code, {required String myCode});

  Future<void> removeFriend(String code);
}

class _Bot {
  _Bot({
    required this.index,
    required this.code,
    required this.nickname,
    required this.avatar,
    required this.dailyXp,
    required this.baseXp,
    required this.streak,
  });

  final int index;
  final String code;
  final String nickname;
  final String avatar;

  /// Average XP earned per day.
  final int dailyXp;

  /// XP earned before this week.
  final int baseXp;
  final int streak;
}

/// Simulated players. Everything is derived from a fixed seed and the date,
/// so numbers are stable within a day and drift from day to day.
class DemoSocialRepository implements SocialRepository {
  DemoSocialRepository({SharedPreferences? prefs, DateTime Function()? clock})
    : _prefs = prefs,
      _clock = clock ?? DateTime.now {
    _bots = _buildBots();
    final saved = _prefs?.getStringList(_friendsKey);
    // First run: start with a few friends so the screen is not empty.
    _friendCodes.addAll(saved ?? _bots.take(4).map((b) => b.code));
  }

  static const _friendsKey = 'demo_friends_v1';
  static const playerCount = 30;

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;
  late final List<_Bot> _bots;
  final Set<String> _friendCodes = {};

  /// How many badges exist, so simulated players never "own" more than that.
  late final int _badgeTotal = buildBadges(
    categories: categories,
    items: knowledgeItems,
  ).length;

  @override
  bool get isDemo => true;

  @override
  List<String> get sampleCodes => _bots
      .skip(4)
      .where((b) => !_friendCodes.contains(b.code))
      .take(3)
      .map((b) => b.code)
      .toList();

  @override
  Future<void> publish(PublicProfile me) async {
    // Nothing to upload: there is no server in demo mode.
  }

  @override
  Future<List<PublicProfile>> friends() async {
    final now = _clock();
    return [
      for (final bot in _bots)
        if (_friendCodes.contains(bot.code)) _profileOf(bot, now),
    ];
  }

  @override
  Future<GlobalBoard> globalBoard(PublicProfile me, {int limit = 20}) async {
    final now = _clock();
    final all = _bots.map((b) => _profileOf(b, now)).toList()
      ..sort(compareByWeeklyXp);
    return GlobalBoard(
      top: all.take(limit).toList(),
      totalPlayers: all.length,
      playersAheadOfMe: all.where((p) => compareByWeeklyXp(p, me) < 0).length,
    );
  }

  @override
  Future<AddFriendResult> addFriend(
    String code, {
    required String myCode,
  }) async {
    final normalized = normalizeCode(code);
    if (normalized == null) return AddFriendResult.invalidCode;
    if (normalized == myCode) return AddFriendResult.selfCode;
    final exists = _bots.any((b) => b.code == normalized);
    if (!exists) return AddFriendResult.notFound;
    if (!_friendCodes.add(normalized)) return AddFriendResult.alreadyFriends;
    await _saveFriends();
    return AddFriendResult.added;
  }

  @override
  Future<void> removeFriend(String code) async {
    if (_friendCodes.remove(code)) await _saveFriends();
  }

  Future<void> _saveFriends() async {
    await _prefs?.setStringList(_friendsKey, _friendCodes.toList());
  }

  // ---- simulation -----------------------------------------------------

  List<_Bot> _buildBots() {
    final random = Random(7);
    final usedNames = <String>{};
    final usedCodes = <String>{};
    // The first four are the default friends: spread from casual to keen so
    // a new player can overtake the first quickly and still has goals.
    const friendDaily = [14, 24, 36, 52];

    final bots = <_Bot>[];
    while (bots.length < playerCount) {
      final adjective = random.nextInt(adjectives.length);
      final animal = random.nextInt(animals.length);
      final identity = Identity(
        adjectiveIndex: adjective,
        animalIndex: animal,
        code: generateFriendCode(random),
      );
      if (!usedNames.add(identity.nickname)) continue;
      if (!usedCodes.add(identity.code)) continue;

      final i = bots.length;
      final daily = i < friendDaily.length
          ? friendDaily[i]
          : 6 + random.nextInt(60);
      bots.add(
        _Bot(
          index: i,
          code: identity.code,
          nickname: identity.nickname,
          avatar: identity.avatar,
          dailyXp: daily,
          baseXp: daily * (10 + random.nextInt(40)),
          streak: random.nextInt(15),
        ),
      );
    }
    return bots;
  }

  PublicProfile _profileOf(_Bot bot, DateTime now) {
    final weekly = _weeklyXp(bot, now);
    final total = bot.baseXp + weekly;
    return PublicProfile(
      code: bot.code,
      nickname: bot.nickname,
      avatar: bot.avatar,
      totalXp: total,
      weeklyXp: weekly,
      streak: bot.streak,
      completed: min(knowledgeItems.length, total ~/ 9),
      badgeCount: min(_badgeTotal, total ~/ 55),
    );
  }

  /// Sum of a bot's simulated XP for Monday through today (today counts half).
  int _weeklyXp(_Bot bot, DateTime now) {
    var sum = 0.0;
    for (var d = 0; d < now.weekday; d++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1) + d,
      );
      final isToday = d == now.weekday - 1;
      sum +=
          bot.dailyXp *
          _jitter(bot.index, _dayNumber(day)) *
          (isToday ? 0.5 : 1);
    }
    return sum.round();
  }

  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// Deterministic pseudo-random factor in 0.6..1.4 for (bot, day).
  /// Park-Miller generator: every step stays below 2^53, so the result is
  /// identical on the VM and in the browser.
  static double _jitter(int botIndex, int dayNumber) {
    var seed = (botIndex * 7919 + dayNumber * 104729 + 17) % 2147483647;
    for (var i = 0; i < 3; i++) {
      seed = seed * 48271 % 2147483647;
    }
    return 0.6 + 0.8 * (seed / 2147483647);
  }
}
