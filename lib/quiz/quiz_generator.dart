import 'dart:math';

import '../models/knowledge_item.dart';

/// Tunable quiz rules.
class QuizConfig {
  const QuizConfig._();

  /// Learned cards needed before the quiz unlocks.
  static const minCards = 5;

  /// Questions per round (fewer if the pool is smaller).
  static const roundSize = 10;

  /// Wrong answers allowed before the round ends.
  static const lives = 3;

  /// Answer choices per question.
  static const optionCount = 4;

  /// Cards the player did not know are this many times likelier to be asked.
  static const priorityWeight = 3;
}

/// Hides every occurrence of [title] inside [content], so a short title that
/// is repeated in its own explanation cannot simply be matched word for word.
String maskTitle(String content, String title) =>
    content.replaceAll(title, '○○○');

/// "Which topic is this explanation about?" - one right title among
/// look-alike wrong ones.
class QuizQuestion {
  QuizQuestion({
    required this.item,
    required this.options,
    required this.correctIndex,
  }) : assert(correctIndex >= 0 && correctIndex < options.length),
       assert(options[correctIndex].id == item.id);

  /// The card being asked about.
  final KnowledgeItem item;

  /// The answer choices (titles are shown), in display order.
  final List<KnowledgeItem> options;
  final int correctIndex;

  /// The explanation shown to the player, with the answer's title hidden.
  String get masked => maskTitle(item.content, item.title);
}

/// Builds up to [count] questions about cards from [pool].
///
/// Wrong options come from [all] and prefer the same category as the answer,
/// so they are plausible. Cards whose id is in [priorityIds] are
/// [QuizConfig.priorityWeight] times as likely to be picked. Every question is
/// about a different card.
List<QuizQuestion> buildQuiz({
  required List<KnowledgeItem> pool,
  required List<KnowledgeItem> all,
  required Random random,
  Set<String> priorityIds = const {},
  int count = QuizConfig.roundSize,
}) {
  if (pool.isEmpty || count <= 0) return const [];

  final chosen = _weightedSample(pool, count, priorityIds, random);
  return [for (final item in chosen) _questionFor(item, all, random)];
}

List<KnowledgeItem> _weightedSample(
  List<KnowledgeItem> pool,
  int count,
  Set<String> priorityIds,
  Random random,
) {
  final remaining = [...pool];
  final picked = <KnowledgeItem>[];

  while (remaining.isNotEmpty && picked.length < count) {
    final weights = [
      for (final item in remaining)
        priorityIds.contains(item.id) ? QuizConfig.priorityWeight : 1,
    ];
    var roll = random.nextInt(weights.reduce((a, b) => a + b));
    var index = 0;
    while (roll >= weights[index]) {
      roll -= weights[index];
      index++;
    }
    picked.add(remaining.removeAt(index));
  }
  return picked;
}

QuizQuestion _questionFor(
  KnowledgeItem item,
  List<KnowledgeItem> all,
  Random random,
) {
  final seenTitles = <String>{item.title};
  final sameCategory = <KnowledgeItem>[];
  final otherCategories = <KnowledgeItem>[];
  for (final other in all) {
    if (other.id == item.id || !seenTitles.add(other.title)) continue;
    (other.categoryId == item.categoryId ? sameCategory : otherCategories).add(
      other,
    );
  }
  sameCategory.shuffle(random);
  otherCategories.shuffle(random);

  final wrong = [
    ...sameCategory,
    ...otherCategories,
  ].take(QuizConfig.optionCount - 1);
  final options = [item, ...wrong]..shuffle(random);

  return QuizQuestion(
    item: item,
    options: options,
    correctIndex: options.indexWhere((o) => o.id == item.id),
  );
}
