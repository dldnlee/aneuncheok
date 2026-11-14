import '../models/category.dart';
import '../models/knowledge_item.dart';

/// Snapshot of everything a badge can depend on. Kept separate from
/// [ProgressStore] so badge rules are plain functions that are easy to test.
class ProgressStats {
  const ProgressStats({
    required this.completed,
    required this.newToMe,
    required this.saved,
    required this.bestStreak,
    required this.goalDays,
    required this.shares,
    required this.bestDayViews,
    required this.completedByCategory,
    required this.totalItems,
  });

  final int completed;

  /// Cards answered with "몰랐어요!".
  final int newToMe;
  final int saved;
  final int bestStreak;

  /// Number of days the daily goal was reached.
  final int goalDays;
  final int shares;

  /// Most cards viewed in a single day.
  final int bestDayViews;
  final Map<String, int> completedByCategory;
  final int totalItems;
}

class AppBadge {
  const AppBadge({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.goal,
    required this.progress,
  });

  final String id;
  final String emoji;
  final String name;
  final String description;

  /// [progress] must reach this for the badge to unlock.
  final int goal;
  final int Function(ProgressStats stats) progress;
}

/// The badge catalog. Category badges are generated from [categories] so a
/// new category automatically gets its own "박사" badge.
List<AppBadge> buildBadges({
  required List<Category> categories,
  required List<KnowledgeItem> items,
}) {
  final perCategory = <String, int>{};
  for (final item in items) {
    perCategory.update(item.categoryId, (n) => n + 1, ifAbsent: () => 1);
  }

  return [
    AppBadge(
      id: 'first_step',
      emoji: '👣',
      name: '첫걸음',
      description: '첫 상식에 반응하기',
      goal: 1,
      progress: (s) => s.completed,
    ),
    AppBadge(
      id: 'curious_20',
      emoji: '🤯',
      name: '호기심 대장',
      description: '"몰랐어요!"를 20번 누르기',
      goal: 20,
      progress: (s) => s.newToMe,
    ),
    AppBadge(
      id: 'knowledge_25',
      emoji: '📚',
      name: '상식 25',
      description: '상식 25개 알아보기',
      goal: 25,
      progress: (s) => s.completed,
    ),
    AppBadge(
      id: 'streak_3',
      emoji: '🔥',
      name: '3일 연속',
      description: '3일 연속으로 접속하기',
      goal: 3,
      progress: (s) => s.bestStreak,
    ),
    AppBadge(
      id: 'streak_7',
      emoji: '🌋',
      name: '일주일 불꽃',
      description: '7일 연속으로 접속하기',
      goal: 7,
      progress: (s) => s.bestStreak,
    ),
    AppBadge(
      id: 'goal_1',
      emoji: '🎯',
      name: '목표 달성',
      description: '하루 목표를 처음 달성하기',
      goal: 1,
      progress: (s) => s.goalDays,
    ),
    AppBadge(
      id: 'goal_7',
      emoji: '🏅',
      name: '꾸준한 사람',
      description: '하루 목표를 7번 달성하기',
      goal: 7,
      progress: (s) => s.goalDays,
    ),
    AppBadge(
      id: 'binge_15',
      emoji: '⚡',
      name: '몰아보기',
      description: '하루에 상식 15개 보기',
      goal: 15,
      progress: (s) => s.bestDayViews,
    ),
    AppBadge(
      id: 'collector',
      emoji: '❤️',
      name: '수집가',
      description: '상식 10개 저장하기',
      goal: 10,
      progress: (s) => s.saved,
    ),
    AppBadge(
      id: 'sharer',
      emoji: '📤',
      name: '전파자',
      description: '상식을 5번 복사해서 공유하기',
      goal: 5,
      progress: (s) => s.shares,
    ),
    for (final c in categories)
      AppBadge(
        id: 'master_${c.id}',
        emoji: c.emoji,
        name: '${c.name} 박사',
        description: '${c.name} 상식을 모두 알아보기',
        goal: perCategory[c.id] ?? 1,
        progress: (s) => s.completedByCategory[c.id] ?? 0,
      ),
    AppBadge(
      id: 'all_clear',
      emoji: '👑',
      name: '올 클리어',
      description: '모든 상식을 알아보기',
      goal: items.isEmpty ? 1 : items.length,
      progress: (s) => s.completedByCategory.values.fold(0, (a, b) => a + b),
    ),
  ];
}
