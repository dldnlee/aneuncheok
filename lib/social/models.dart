/// What other players can see about someone. Deliberately minimal: an
/// anonymous nickname, an emoji avatar and game stats - no personal data.
class PublicProfile {
  const PublicProfile({
    required this.code,
    required this.nickname,
    required this.avatar,
    required this.totalXp,
    required this.weeklyXp,
    required this.streak,
    required this.completed,
    required this.badgeCount,
  });

  /// Friend code, e.g. `K7QW3X`. Unique per player.
  final String code;
  final String nickname;
  final String avatar;
  final int totalXp;
  final int weeklyXp;
  final int streak;
  final int completed;
  final int badgeCount;

  Map<String, Object> toJson() => {
    'code': code,
    'nickname': nickname,
    'avatar': avatar,
    'totalXp': totalXp,
    'weeklyXp': weeklyXp,
    'streak': streak,
    'completed': completed,
    'badgeCount': badgeCount,
  };

  factory PublicProfile.fromJson(Map<String, dynamic> json) => PublicProfile(
    code: json['code'] as String,
    nickname: json['nickname'] as String,
    avatar: json['avatar'] as String,
    totalXp: json['totalXp'] as int,
    weeklyXp: json['weeklyXp'] as int,
    streak: json['streak'] as int,
    completed: json['completed'] as int,
    badgeCount: json['badgeCount'] as int,
  );
}

/// One row of a leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.profile,
    required this.rank,
    required this.isMe,
  });

  final PublicProfile profile;

  /// 1-based position by weekly XP.
  final int rank;
  final bool isMe;
}

/// Weekly-XP ordering used by every leaderboard: more XP first, then more
/// total XP, then code so the order is always stable.
int compareByWeeklyXp(PublicProfile a, PublicProfile b) {
  final byWeek = b.weeklyXp.compareTo(a.weeklyXp);
  if (byWeek != 0) return byWeek;
  final byTotal = b.totalXp.compareTo(a.totalXp);
  if (byTotal != 0) return byTotal;
  return a.code.compareTo(b.code);
}

/// The global top list plus where the current player stands.
class GlobalBoard {
  const GlobalBoard({
    required this.top,
    required this.totalPlayers,
    required this.playersAheadOfMe,
  });

  /// Best players this week, best first. Never includes the current player.
  final List<PublicProfile> top;

  /// Number of players on the board, not counting the current player.
  final int totalPlayers;

  /// Players (other than me) who have more weekly XP than I do.
  final int playersAheadOfMe;
}

enum AddFriendResult { added, alreadyFriends, notFound, selfCode, invalidCode }
