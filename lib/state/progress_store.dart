import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Level {
  const Level(this.minCompleted, this.emoji, this.name);

  final int minCompleted;
  final String emoji;
  final String name;
}

const List<Level> levels = [
  Level(0, '🌱', '상식 새싹'),
  Level(5, '🌿', '상식 꿈나무'),
  Level(15, '😎', '상식 러버'),
  Level(30, '🔥', '상식 고수'),
  Level(50, '🎓', '상식 박사'),
  Level(60, '👑', '상식 마스터'),
];

class ViewResult {
  const ViewResult({this.streakIncreased = false, this.goalReached = false});

  /// First activity of a new day.
  final bool streakIncreased;

  /// This view was the one that completed today's goal.
  final bool goalReached;
}

class CompleteResult {
  const CompleteResult({required this.firstTime, this.leveledUpTo});

  /// False when the user just changed an earlier reaction.
  final bool firstTime;
  final Level? leveledUpTo;
}

/// Player progress: reactions, saved cards, daily streak and daily goal.
///
/// Pass a [SharedPreferences] to persist; without one the store is purely
/// in-memory (used by tests). [clock] is injectable so streaks are testable.
class ProgressStore extends ChangeNotifier {
  ProgressStore({SharedPreferences? prefs, DateTime Function()? clock})
    : _prefs = prefs,
      _clock = clock ?? DateTime.now {
    _restore();
  }

  static const _prefsKey = 'progress_v1';

  /// Cards to look at each day to hit the daily goal.
  static const dailyGoal = 5;

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;

  /// id -> true when the card was new to the user, false when already known.
  final Map<String, bool> _completed = {};
  final Set<String> _saved = {};
  final Set<String> _viewedToday = {};
  String? _viewedDay;
  String? _lastActiveDay;
  int _streak = 0;

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

  bool get activeToday => _lastActiveDay == _today;

  int get todayViewed => _viewedDay == _today ? _viewedToday.length : 0;
  bool get goalReached => todayViewed >= dailyGoal;

  Level get level => levels.lastWhere((l) => completedCount >= l.minCompleted);

  int get levelNumber => levels.indexOf(level) + 1;

  Level? get nextLevel {
    for (final l in levels) {
      if (l.minCompleted > completedCount) return l;
    }
    return null;
  }

  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 1;
    final cur = level;
    return (completedCount - cur.minCompleted) /
        (next.minCompleted - cur.minCompleted);
  }

  // ---- writes ---------------------------------------------------------

  /// Call when a card is shown. Counts toward streak and daily goal.
  ViewResult recordView(String id) {
    final streakUp = _touch();
    final today = _today;
    if (_viewedDay != today) {
      _viewedDay = today;
      _viewedToday.clear();
    }
    final added = _viewedToday.add(id);
    final goalNow = added && _viewedToday.length == dailyGoal;
    if (streakUp || added) {
      _persist();
      notifyListeners();
    }
    return ViewResult(streakIncreased: streakUp, goalReached: goalNow);
  }

  CompleteResult complete(String id, {required bool newToMe}) {
    _touch();
    final firstTime = !_completed.containsKey(id);
    final before = level;
    _completed[id] = newToMe;
    final after = level;
    _persist();
    notifyListeners();
    return CompleteResult(
      firstTime: firstTime,
      leveledUpTo: firstTime && after.minCompleted != before.minCompleted
          ? after
          : null,
    );
  }

  /// Returns true when the card is saved after the call.
  bool toggleSaved(String id) {
    final nowSaved = _saved.add(id);
    if (!nowSaved) _saved.remove(id);
    _persist();
    notifyListeners();
    return nowSaved;
  }

  void save(String id) {
    if (_saved.add(id)) {
      _persist();
      notifyListeners();
    }
  }

  // ---- internals ------------------------------------------------------

  String get _today => _dayKey(_clock());

  String get _yesterday {
    final n = _clock();
    return _dayKey(DateTime(n.year, n.month, n.day - 1));
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
    _lastActiveDay = today;
    return true;
  }

  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(
      _prefsKey,
      jsonEncode({
        'completed': _completed,
        'saved': _saved.toList(),
        'streak': _streak,
        'lastActiveDay': _lastActiveDay,
        'viewedDay': _viewedDay,
        'viewedToday': _viewedToday.toList(),
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
      _streak = data['streak'] as int? ?? 0;
      _lastActiveDay = data['lastActiveDay'] as String?;
      _viewedDay = data['viewedDay'] as String?;
      _viewedToday.addAll((data['viewedToday'] as List? ?? []).cast<String>());
    } catch (_) {
      // Corrupt data: start fresh rather than crash on launch.
      _completed.clear();
      _saved.clear();
      _viewedToday.clear();
      _streak = 0;
      _lastActiveDay = null;
      _viewedDay = null;
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
