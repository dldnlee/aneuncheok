import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dummy_data.dart';
import '../models/knowledge_item.dart';
import 'badges.dart';

class Level {
  const Level(this.minXp, this.emoji, this.name);

  /// Total XP needed to reach this level.
  final int minXp;
  final String emoji;
  final String name;
}

const List<Level> levels = [
  Level(0, '🌱', '상식 새싹'),
  Level(30, '🌿', '상식 꿈나무'),
  Level(80, '😎', '상식 러버'),
  Level(150, '🔥', '상식 고수'),
  Level(250, '🧠', '척척박사'),
  Level(400, '🎓', '상식 박사'),
  Level(600, '🏆', '상식 달인'),
  Level(850, '👑', '상식 마스터'),
  // The card library has grown well past 200 cards, so there is room above
  // the old cap for players who keep going.
  Level(1200, '🦸', '상식 영웅'),
  Level(1700, '🌟', '상식 레전드'),
  Level(2300, '💎', '상식 그랜드마스터'),
];

/// The level a player with [xp] total XP is on.
Level levelForXp(int xp) => levels.lastWhere((l) => xp >= l.minXp);

/// 1-based level number for [xp].
int levelNumberForXp(int xp) => levels.indexOf(levelForXp(xp)) + 1;

/// How much XP each action is worth.
class XpRewards {
  const XpRewards._();

  static const newToMe = 10;
  static const alreadyKnew = 6;
  static const dailyGoal = 25;
  static const categoryMastery = 50;

  /// Remembering a card in review mode.
  static const reviewed = 5;

  /// Bonus for remembering a card at the last step, when it "graduates".
  static const graduated = 25;

  /// Bonus for the first activity of a day, growing with the streak up to
  /// 7 days. A 1-day streak earns nothing.
  static int streakBonus(int streak) =>
      streak < 2 ? 0 : 5 * math.min(streak, 7);
}

/// Spaced repetition: a card you marked "몰랐어요" comes back for review after
/// these many days. Remembering it moves it up one step, forgetting it sends
/// it back to the first step, and remembering it at the last step graduates it.
class ReviewSchedule {
  const ReviewSchedule._();

  static const List<int> intervals = [1, 3, 7, 14, 30];

  /// Most cards in one review session, so a big backlog is not overwhelming.
  static const sessionLimit = 20;
}

/// What happened when a card was answered in review mode.
class ReviewResult {
  const ReviewResult({
    this.applied = false,
    this.remembered = false,
    this.xpGained = 0,
    this.nextInDays,
    this.graduated = false,
    this.leveledUpTo,
  });

  /// False when the card was not due, so nothing changed.
  final bool applied;
  final bool remembered;
  final int xpGained;

  /// Days until the card comes back, or null when it graduated.
  final int? nextInDays;
  final bool graduated;
  final Level? leveledUpTo;
}

class _ReviewState {
  _ReviewState(this.step, this.due);

  /// Index into [ReviewSchedule.intervals].
  int step;

  /// Day key (yyyy-mm-dd) the card is next due. Due on or before today = due.
  String due;
}

/// What happened as a result of viewing or reacting to a card.
class ActivityResult {
  const ActivityResult({
    this.xpGained = 0,
    this.leveledUpTo,
    this.streakIncreased = false,
    this.goalReached = false,
    this.firstTime = false,
    this.masteredCategoryId,
  });

  final int xpGained;
  final Level? leveledUpTo;

  /// First activity of a new day.
  final bool streakIncreased;

  /// This action completed today's goal.
  final bool goalReached;

  /// For reactions: false when the user just changed an earlier reaction.
  final bool firstTime;

  /// Set when this reaction finished every card in a category.
  final String? masteredCategoryId;
}

/// Player progress: reactions, XP and levels, saved cards, daily streak,
/// daily goal and badges.
///
/// Pass a [SharedPreferences] to persist; without one the store is purely
/// in-memory (used by tests). [clock] is injectable so streaks are testable.
class ProgressStore extends ChangeNotifier {
  ProgressStore({
    SharedPreferences? prefs,
    DateTime Function()? clock,
    List<KnowledgeItem>? items,
    List<AppBadge>? badges,
  }) : _prefs = prefs,
       _clock = clock ?? DateTime.now {
    final all = items ?? knowledgeItems;
    for (final item in all) {
      _categoryOfItem[item.id] = item.categoryId;
      _totalPerCategory.update(
        item.categoryId,
        (n) => n + 1,
        ifAbsent: () => 1,
      );
    }
    _totalItems = all.length;
    this.badges = badges ?? buildBadges(categories: categories, items: all);
    _restore();
  }

  static const _prefsKey = 'progress_v1';

  /// Cards to look at each day to hit the daily goal.
  static const dailyGoal = 5;

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  /// The badge catalog this store evaluates.
  late final List<AppBadge> badges;

  final Map<String, String> _categoryOfItem = {};
  final Map<String, int> _totalPerCategory = {};
  late final int _totalItems;

  /// id -> true when the card was new to the user, false when already known.
  final Map<String, bool> _completed = {};
  final Set<String> _saved = {};
  final Set<String> _viewedToday = {};
  final Set<String> _mastered = {};

  /// Cards waiting to be reviewed again (marked "몰랐어요").
  final Map<String, _ReviewState> _review = {};

  /// Cards that went through every review step. They never come back.
  final Set<String> _graduated = {};
  int _reviews = 0;

  /// badge id -> day key it was unlocked.
  final Map<String, String> _badgeUnlocked = {};
  final List<AppBadge> _pendingBadges = [];

  String? _viewedDay;
  String? _lastActiveDay;
  int _streak = 0;
  int _bestStreak = 0;
  int _goalDays = 0;
  int _bestDayViews = 0;
  int _shares = 0;
  int _xp = 0;
  int _weeklyXp = 0;
  String? _weekKey;

  // ---- reads ----------------------------------------------------------

  bool isCompleted(String id) => _completed.containsKey(id);

  /// null = no reaction yet, true = "몰랐어요", false = "알고 있었어요".
  bool? reactionFor(String id) => _completed[id];

  bool isSaved(String id) => _saved.contains(id);

  int get completedCount => _completed.length;
  int get savedCount => _saved.length;

  int completedIn(Iterable<String> ids) => ids.where(isCompleted).length;

  /// Consecutive active days. Drops to 0 once a whole day has been missed.
  int get currentStreak {
    final last = _lastActiveDay;
    if (last == null) return 0;
    return (last == _today || last == _yesterday) ? _streak : 0;
  }

  int get bestStreak => _bestStreak;
  bool get activeToday => _lastActiveDay == _today;

  int get todayViewed => _viewedDay == _today ? _viewedToday.length : 0;
  bool get goalReached => todayViewed >= dailyGoal;

  int get goalDays => _goalDays;
  int get shares => _shares;

  // Review (spaced repetition)

  bool isInReview(String id) => _review.containsKey(id);

  bool isDue(String id) {
    final state = _review[id];
    return state != null && state.due.compareTo(_today) <= 0;
  }

  /// Cards due for review today or earlier.
  int get dueCount => _review.values.where(_isDueState).length;

  /// Every card still in the review queue, due or not.
  int get reviewQueueCount => _review.length;

  /// Successful reviews so far ("기억나요").
  int get reviewCount => _reviews;

  /// Cards that finished every review step.
  int get graduatedCount => _graduated.length;

  bool isGraduated(String id) => _graduated.contains(id);

  /// Ids due for review, longest overdue first, at most [limit].
  List<String> dueIds({int limit = ReviewSchedule.sessionLimit}) {
    final due = _review.entries.where((e) => _isDueState(e.value)).toList()
      ..sort((a, b) {
        final byDue = a.value.due.compareTo(b.value.due);
        return byDue != 0 ? byDue : a.key.compareTo(b.key);
      });
    return due.take(limit).map((e) => e.key).toList();
  }

  /// Days until the next card is due, or null when nothing is waiting.
  /// 0 means something is due today.
  int? get daysUntilNextReview {
    if (_review.isEmpty) return null;
    final earliest = _review.values
        .map((s) => s.due)
        .reduce((a, b) => a.compareTo(b) <= 0 ? a : b);
    return math.max(0, _dayNumber(earliest) - _dayNumber(_today));
  }

  /// 1-based step of [id] on the review ladder, or null if not in review.
  int? reviewStep(String id) {
    final state = _review[id];
    return state == null ? null : state.step + 1;
  }

  static int get reviewSteps => ReviewSchedule.intervals.length;

  bool _isDueState(_ReviewState s) => s.due.compareTo(_today) <= 0;

  // XP and levels

  int get xp => _xp;

  /// XP earned since Monday. Resets automatically when a new week starts.
  int get weeklyXp => _weekKey == _thisWeek ? _weeklyXp : 0;

  Level get level => levelForXp(_xp);
  int get levelNumber => levelNumberForXp(_xp);

  Level? get nextLevel {
    for (final l in levels) {
      if (l.minXp > _xp) return l;
    }
    return null;
  }

  /// 0..1 progress from the current level toward the next one.
  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    final cur = level;
    return (_xp - cur.minXp) / (next.minXp - cur.minXp);
  }

  /// Whole days left in the current week (Mon-Sun), counting today.
  int get daysLeftInWeek => 8 - _clock().weekday;

  // Badges

  bool hasBadge(String id) => _badgeUnlocked.containsKey(id);
  int get badgeCount => _badgeUnlocked.length;

  /// Progress toward [badge], capped at its goal.
  int badgeProgress(AppBadge badge) =>
      math.min(badge.progress(stats), badge.goal);

  ProgressStats get stats {
    final byCategory = <String, int>{};
    for (final id in _completed.keys) {
      final cat = _categoryOfItem[id];
      if (cat != null) byCategory.update(cat, (n) => n + 1, ifAbsent: () => 1);
    }
    return ProgressStats(
      completed: _completed.length,
      newToMe: _completed.values.where((v) => v).length,
      saved: _saved.length,
      bestStreak: _bestStreak,
      goalDays: _goalDays,
      shares: _shares,
      bestDayViews: _bestDayViews,
      completedByCategory: byCategory,
      totalItems: _totalItems,
      reviews: _reviews,
      graduated: _graduated.length,
    );
  }

  /// Badges unlocked since the last call. The UI shows these as a pop-up.
  List<AppBadge> drainNewBadges() {
    final out = List<AppBadge>.of(_pendingBadges);
    _pendingBadges.clear();
    return out;
  }

  // ---- writes ---------------------------------------------------------

  /// Call when a card is shown. Counts toward streak and daily goal.
  ActivityResult recordView(String id) {
    final before = level;
    var xp = 0;

    final streakUp = _touch();
    if (streakUp) xp += XpRewards.streakBonus(_streak);

    final today = _today;
    if (_viewedDay != today) {
      _viewedDay = today;
      _viewedToday.clear();
    }
    final added = _viewedToday.add(id);
    final goalNow = added && _viewedToday.length == dailyGoal;
    if (goalNow) {
      xp += XpRewards.dailyGoal;
      _goalDays++;
    }
    _bestDayViews = math.max(_bestDayViews, _viewedToday.length);

    if (xp > 0) _gain(xp);
    final fresh = _evaluateBadges();

    if (streakUp || added || fresh) {
      _persist();
      notifyListeners();
    }
    return ActivityResult(
      xpGained: xp,
      leveledUpTo: _levelUpFrom(before),
      streakIncreased: streakUp,
      goalReached: goalNow,
    );
  }

  ActivityResult complete(String id, {required bool newToMe}) {
    final before = level;
    var xp = 0;

    final streakUp = _touch();
    if (streakUp) xp += XpRewards.streakBonus(_streak);

    final firstTime = !_completed.containsKey(id);
    _completed[id] = newToMe;

    // Cards you did not know join the review queue; cards you already knew
    // leave it. Graduated cards never come back.
    if (newToMe) {
      if (!_graduated.contains(id)) {
        _review.putIfAbsent(
          id,
          () => _ReviewState(0, _dayAfter(ReviewSchedule.intervals[0])),
        );
      }
    } else {
      _review.remove(id);
    }

    String? mastered;
    if (firstTime) {
      xp += newToMe ? XpRewards.newToMe : XpRewards.alreadyKnew;
      final cat = _categoryOfItem[id];
      if (cat != null && _isCategoryDone(cat) && _mastered.add(cat)) {
        xp += XpRewards.categoryMastery;
        mastered = cat;
      }
    }

    if (xp > 0) _gain(xp);
    _evaluateBadges();
    _persist();
    notifyListeners();

    return ActivityResult(
      xpGained: xp,
      leveledUpTo: _levelUpFrom(before),
      streakIncreased: streakUp,
      firstTime: firstTime,
      masteredCategoryId: mastered,
    );
  }

  /// Answers a card in review mode. Only cards that are due can be answered,
  /// so the same card cannot be answered twice for XP.
  ReviewResult review(String id, {required bool remembered}) {
    final state = _review[id];
    if (state == null || !_isDueState(state)) return const ReviewResult();

    final before = level;
    var xp = 0;
    final streakUp = _touch();
    if (streakUp) xp += XpRewards.streakBonus(_streak);

    var graduated = false;
    int? nextInDays;
    if (remembered) {
      _reviews++;
      xp += XpRewards.reviewed;
      final next = state.step + 1;
      if (next >= ReviewSchedule.intervals.length) {
        _review.remove(id);
        _graduated.add(id);
        graduated = true;
        xp += XpRewards.graduated;
      } else {
        state.step = next;
        nextInDays = ReviewSchedule.intervals[next];
        state.due = _dayAfter(nextInDays);
      }
    } else {
      state.step = 0;
      nextInDays = ReviewSchedule.intervals[0];
      state.due = _dayAfter(nextInDays);
    }

    if (xp > 0) _gain(xp);
    _evaluateBadges();
    _persist();
    notifyListeners();

    return ReviewResult(
      applied: true,
      remembered: remembered,
      xpGained: xp,
      nextInDays: nextInDays,
      graduated: graduated,
      leveledUpTo: _levelUpFrom(before),
    );
  }

  /// Returns true when the card is saved after the call.
  bool toggleSaved(String id) {
    final nowSaved = _saved.add(id);
    if (!nowSaved) _saved.remove(id);
    _evaluateBadges();
    _persist();
    notifyListeners();
    return nowSaved;
  }

  void save(String id) {
    if (_saved.add(id)) {
      _evaluateBadges();
      _persist();
      notifyListeners();
    }
  }

  /// Call when the user copies a card to share it.
  void recordShare() {
    _shares++;
    _evaluateBadges();
    _persist();
    notifyListeners();
  }

  // ---- internals ------------------------------------------------------

  String get _today => _dayKey(_clock());

  String get _yesterday {
    final n = _clock();
    return _dayKey(DateTime(n.year, n.month, n.day - 1));
  }

  /// The day key [days] days from today.
  String _dayAfter(int days) {
    final n = _clock();
    return _dayKey(DateTime(n.year, n.month, n.day + days));
  }

  /// Whole days since the epoch for a yyyy-mm-dd key. Uses UTC so daylight
  /// saving changes cannot make a day 23 or 25 hours long.
  static int _dayNumber(String key) {
    final p = key.split('-');
    return DateTime.utc(
          int.parse(p[0]),
          int.parse(p[1]),
          int.parse(p[2]),
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  /// Monday of the current week.
  String get _thisWeek {
    final n = _clock();
    return _dayKey(DateTime(n.year, n.month, n.day - (n.weekday - 1)));
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Marks today as active. Returns true if this is the first activity today.
  bool _touch() {
    final today = _today;
    if (_lastActiveDay == today) return false;
    _streak = _lastActiveDay == _yesterday ? _streak + 1 : 1;
    _bestStreak = math.max(_bestStreak, _streak);
    _lastActiveDay = today;
    return true;
  }

  void _gain(int amount) {
    final week = _thisWeek;
    if (_weekKey != week) {
      _weekKey = week;
      _weeklyXp = 0;
    }
    _xp += amount;
    _weeklyXp += amount;
  }

  Level? _levelUpFrom(Level before) {
    final after = level;
    return after.minXp != before.minXp ? after : null;
  }

  bool _isCategoryDone(String categoryId) {
    final total = _totalPerCategory[categoryId] ?? 0;
    if (total == 0) return false;
    final done = _completed.keys
        .where((id) => _categoryOfItem[id] == categoryId)
        .length;
    return done >= total;
  }

  /// Unlocks any badge whose goal is now met. Returns true if one unlocked.
  bool _evaluateBadges() {
    final s = stats;
    var any = false;
    for (final badge in badges) {
      if (_badgeUnlocked.containsKey(badge.id)) continue;
      if (badge.progress(s) >= badge.goal) {
        _badgeUnlocked[badge.id] = _today;
        _pendingBadges.add(badge);
        any = true;
      }
    }
    return any;
  }

  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(
      _prefsKey,
      jsonEncode({
        'completed': _completed,
        'saved': _saved.toList(),
        'mastered': _mastered.toList(),
        'badges': _badgeUnlocked,
        'streak': _streak,
        'bestStreak': _bestStreak,
        'lastActiveDay': _lastActiveDay,
        'viewedDay': _viewedDay,
        'viewedToday': _viewedToday.toList(),
        'goalDays': _goalDays,
        'bestDayViews': _bestDayViews,
        'shares': _shares,
        'xp': _xp,
        'weeklyXp': _weeklyXp,
        'weekKey': _weekKey,
        'review': {
          for (final e in _review.entries)
            e.key: {'step': e.value.step, 'due': e.value.due},
        },
        'graduated': _graduated.toList(),
        'reviews': _reviews,
      }),
    );
  }

  void _restore() {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _completed.addAll(
        (data['completed'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v == true),
        ),
      );
      _saved.addAll((data['saved'] as List? ?? []).cast<String>());
      _mastered.addAll((data['mastered'] as List? ?? []).cast<String>());
      _badgeUnlocked.addAll(
        (data['badges'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v as String),
        ),
      );
      _streak = data['streak'] as int? ?? 0;
      _bestStreak = data['bestStreak'] as int? ?? _streak;
      _lastActiveDay = data['lastActiveDay'] as String?;
      _viewedDay = data['viewedDay'] as String?;
      _viewedToday.addAll((data['viewedToday'] as List? ?? []).cast<String>());
      _goalDays = data['goalDays'] as int? ?? 0;
      _bestDayViews = data['bestDayViews'] as int? ?? 0;
      _shares = data['shares'] as int? ?? 0;
      // Progress saved before XP existed: grant the XP those reactions earn.
      _xp =
          data['xp'] as int? ??
          _completed.values.fold<int>(
            0,
            (sum, newToMe) =>
                sum + (newToMe ? XpRewards.newToMe : XpRewards.alreadyKnew),
          );
      _weeklyXp = data['weeklyXp'] as int? ?? 0;
      _weekKey = data['weekKey'] as String?;
      (data['review'] as Map<String, dynamic>? ?? {}).forEach((id, v) {
        final m = v as Map<String, dynamic>;
        final step = (m['step'] as int).clamp(
          0,
          ReviewSchedule.intervals.length - 1,
        );
        _review[id] = _ReviewState(step, m['due'] as String);
      });
      _graduated.addAll((data['graduated'] as List? ?? []).cast<String>());
      _reviews = data['reviews'] as int? ?? 0;
    } catch (_) {
      // Corrupt data: start fresh rather than crash on launch.
      _completed.clear();
      _saved.clear();
      _mastered.clear();
      _badgeUnlocked.clear();
      _viewedToday.clear();
      _streak = 0;
      _bestStreak = 0;
      _lastActiveDay = null;
      _viewedDay = null;
      _goalDays = 0;
      _bestDayViews = 0;
      _shares = 0;
      _xp = 0;
      _weeklyXp = 0;
      _weekKey = null;
      _review.clear();
      _graduated.clear();
      _reviews = 0;
    }
  }
}

/// Makes the [ProgressStore] available below [MaterialApp].
class ProgressScope extends InheritedNotifier<ProgressStore> {
  const ProgressScope({
    super.key,
    required ProgressStore store,
    required super.child,
  }) : super(notifier: store);

  /// Rebuilds the caller whenever progress changes.
  static ProgressStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'No ProgressScope found in context');
    return scope!.notifier!;
  }

  /// Gets the store without subscribing to changes.
  static ProgressStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<ProgressScope>();
    assert(scope != null, 'No ProgressScope found in context');
    return scope!.notifier!;
  }
}
