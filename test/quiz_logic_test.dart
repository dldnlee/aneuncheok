import 'dart:math';

import 'package:aneuncheok/data/dummy_data.dart';
import 'package:aneuncheok/models/knowledge_item.dart';
import 'package:aneuncheok/quiz/quiz_generator.dart';
import 'package:aneuncheok/quiz/quiz_session.dart';
import 'package:flutter_test/flutter_test.dart';

KnowledgeItem card(String id, String cat, {String? title, String? content}) =>
    KnowledgeItem(
      id: id,
      categoryId: cat,
      title: title ?? 'title $id',
      content: content ?? 'content of $id',
    );

List<KnowledgeItem> cards(String cat, int n, {String prefix = ''}) => [
  for (var i = 1; i <= n; i++) card('$prefix$cat$i', cat),
];

QuizQuestion question(List<KnowledgeItem> options, int correct) => QuizQuestion(
  item: options[correct],
  options: options,
  correctIndex: correct,
);

void main() {
  group('buildQuiz', () {
    final a = cards('a', 8);
    final b = cards('b', 8);
    final all = [...a, ...b];

    test('asks about distinct cards, each with four distinct options', () {
      final quiz = buildQuiz(pool: all, all: all, random: Random(1));

      expect(quiz, hasLength(QuizConfig.roundSize));
      expect(quiz.map((q) => q.item.id).toSet(), hasLength(quiz.length));
      for (final q in quiz) {
        expect(q.options, hasLength(QuizConfig.optionCount));
        expect(q.options.map((o) => o.id).toSet(), hasLength(4));
        expect(q.options.map((o) => o.title).toSet(), hasLength(4));
        expect(q.options[q.correctIndex].id, q.item.id);
        expect(
          q.options.where((o) => o.id == q.item.id),
          hasLength(1),
          reason: 'exactly one right answer',
        );
      }
    });

    test('asks fewer questions when the pool is small', () {
      final quiz = buildQuiz(
        pool: a.take(6).toList(),
        all: all,
        random: Random(1),
      );
      expect(quiz, hasLength(6));
    });

    test('returns nothing for an empty pool or a zero count', () {
      expect(buildQuiz(pool: [], all: all, random: Random(1)), isEmpty);
      expect(
        buildQuiz(pool: all, all: all, random: Random(1), count: 0),
        isEmpty,
      );
    });

    test('wrong options come from the same category when possible', () {
      final quiz = buildQuiz(pool: a, all: all, random: Random(2), count: 8);

      for (final q in quiz) {
        expect(
          q.options.every((o) => o.categoryId == 'a'),
          isTrue,
          reason: 'category "a" has plenty of look-alikes',
        );
      }
    });

    test('falls back to other categories when a category is too small', () {
      final small = cards('s', 2);
      final everything = [...small, ...b];

      final quiz = buildQuiz(
        pool: [small.first],
        all: everything,
        random: Random(3),
      );

      final options = quiz.single.options;
      expect(options.where((o) => o.categoryId == 's'), hasLength(2));
      expect(options.where((o) => o.categoryId == 'b'), hasLength(2));
    });

    test('never offers two options with the same title', () {
      final twins = [
        card('x1', 'a', title: 'same'),
        card('x2', 'a', title: 'same'),
        ...cards('a', 5, prefix: 'y'),
      ];

      for (var seed = 0; seed < 30; seed++) {
        final quiz = buildQuiz(pool: twins, all: twins, random: Random(seed));
        for (final q in quiz) {
          expect(
            q.options.map((o) => o.title).toSet(),
            hasLength(q.options.length),
          );
        }
      }
    });

    test('with too few cards overall it still includes the right answer', () {
      final tiny = [card('t1', 'a'), card('t2', 'a')];

      final quiz = buildQuiz(pool: tiny, all: tiny, random: Random(1));

      for (final q in quiz) {
        expect(q.options, hasLength(2));
        expect(q.options[q.correctIndex].id, q.item.id);
      }
    });

    test('is deterministic for a seed and varies between seeds', () {
      List<String> ids(int seed) =>
          buildQuiz(pool: all, all: all, random: Random(seed))
              .map(
                (q) => '${q.item.id}:${q.options.map((o) => o.id).join(',')}',
              )
              .toList();

      expect(ids(7), ids(7));
      expect(ids(7), isNot(ids(8)));
    });

    test('the right answer is not always in the same position', () {
      final positions = <int>{};
      for (var seed = 0; seed < 40; seed++) {
        positions.addAll(
          buildQuiz(
            pool: all,
            all: all,
            random: Random(seed),
          ).map((q) => q.correctIndex),
        );
      }
      expect(positions, {0, 1, 2, 3});
    });

    test('cards the player did not know are asked more often', () {
      final pool = cards('a', 10);
      final priority = pool.take(5).map((c) => c.id).toSet();
      var hits = 0;
      const draws = 400;

      for (var seed = 0; seed < draws; seed++) {
        final first = buildQuiz(
          pool: pool,
          all: all,
          random: Random(seed),
          priorityIds: priority,
          count: 1,
        ).single;
        if (priority.contains(first.item.id)) hits++;
      }

      // Expected share is 3*5 / (3*5 + 5) = 75%; uniform would be 50%.
      expect(hits / draws, greaterThan(0.65));
    });
  });

  group('maskTitle', () {
    test('hides every occurrence of the title', () {
      expect(
        maskTitle('"윤슬"은 반짝이는 물결이에요. 윤슬이 예뻐요.', '윤슬'),
        '"○○○"은 반짝이는 물결이에요. ○○○이 예뻐요.',
      );
    });

    test('leaves text alone when the title is not in it', () {
      expect(maskTitle('물은 100℃에서 끓어요.', '물이 끓는 온도'), '물은 100℃에서 끓어요.');
    });

    test('is what the question shows', () {
      final c = card('w1', 'a', title: 'AB', content: 'about AB and more AB');
      final q = question([
        c,
        card('w2', 'a'),
        card('w3', 'a'),
        card('w4', 'a'),
      ], 0);
      expect(q.masked, 'about ○○○ and more ○○○');
    });
  });

  group('with the real cards', () {
    test('every card makes a valid question', () {
      for (final item in knowledgeItems) {
        final q = buildQuiz(
          pool: [item],
          all: knowledgeItems,
          random: Random(item.id.hashCode),
        ).single;

        expect(q.options, hasLength(QuizConfig.optionCount), reason: item.id);
        expect(
          q.options.map((o) => o.title).toSet(),
          hasLength(4),
          reason: item.id,
        );
        expect(q.options[q.correctIndex].id, item.id, reason: item.id);
        expect(
          q.options.where((o) => o.categoryId == item.categoryId),
          hasLength(4),
          reason: '${item.id}: every category is large enough for look-alikes',
        );
      }
    });

    test('the answer never gives itself away through its own title', () {
      for (final item in knowledgeItems) {
        final masked = maskTitle(item.content, item.title);
        expect(masked.contains(item.title), isFalse, reason: item.id);
      }
    });
  });

  group('QuizSession', () {
    late List<QuizQuestion> qs;

    setUp(() {
      final pool = cards('a', 12);
      qs = [
        for (var i = 0; i < 5; i++)
          question([
            pool[i],
            pool[5 + i],
            pool[(6 + i) % 12],
            pool[(7 + i) % 12],
          ], 0),
      ];
    });

    test('starts fresh', () {
      final s = QuizSession(qs);

      expect(s.index, 0);
      expect(s.total, 5);
      expect(s.lives, QuizConfig.lives);
      expect(s.combo, 0);
      expect(s.answered, isFalse);
      expect(s.finished, isFalse);
      expect(s.current, same(qs.first));
    });

    test('a right answer raises the combo and keeps every life', () {
      final s = QuizSession(qs);

      final out = s.answer(0);

      expect(out.correct, isTrue);
      expect(out.combo, 1);
      expect(out.livesLeft, QuizConfig.lives);
      expect(out.correctIndex, 0);
      expect(out.finished, isFalse);
      expect(s.correctCount, 1);
      expect(s.picked, 0);
      expect(s.missed, isEmpty);
    });

    test('a wrong answer costs a life, resets the combo and is remembered', () {
      final s = QuizSession(qs);
      s.answer(0);
      s.next();
      s.answer(0);
      s.next();
      expect(s.combo, 2);

      final out = s.answer(2);

      expect(out.correct, isFalse);
      expect(out.combo, 0);
      expect(out.livesLeft, QuizConfig.lives - 1);
      expect(s.bestCombo, 2, reason: 'the best run is kept');
      expect(s.missed, [qs[2]]);
    });

    test('a question can only be answered once', () {
      final s = QuizSession(qs)..answer(0);
      expect(() => s.answer(1), throwsStateError);
    });

    test('rejects an option that does not exist', () {
      final s = QuizSession(qs);
      expect(() => s.answer(4), throwsRangeError);
      expect(() => s.answer(-1), throwsRangeError);
      expect(s.answered, isFalse);
    });

    test('cannot move on before answering', () {
      final s = QuizSession(qs);
      expect(s.next, throwsStateError);
    });

    test('walks through every question and finishes on the last answer', () {
      final s = QuizSession(qs);
      for (var i = 0; i < 4; i++) {
        expect(s.answer(0).finished, isFalse);
        s.next();
        expect(s.index, i + 1);
        expect(s.answered, isFalse);
      }

      final last = s.answer(0);

      expect(last.finished, isTrue);
      expect(s.finished, isTrue);
      expect(s.perfect, isTrue);
      expect(s.bestCombo, 5);
      expect(s.next, throwsStateError, reason: 'the round is over');
    });

    test('a single mistake means the round is not perfect', () {
      final s = QuizSession(qs);
      s.answer(1);
      s.next();
      for (var i = 0; i < 4; i++) {
        s.answer(0);
        if (i < 3) s.next();
      }

      expect(s.finished, isTrue);
      expect(s.lives, QuizConfig.lives - 1, reason: 'still alive');
      expect(s.perfect, isFalse);
    });

    test('running out of lives ends the round early', () {
      final s = QuizSession(qs);
      for (var i = 0; i < QuizConfig.lives; i++) {
        final out = s.answer(3);
        expect(out.finished, i == QuizConfig.lives - 1);
        if (i < QuizConfig.lives - 1) s.next();
      }

      expect(s.lives, 0);
      expect(s.finished, isTrue);
      expect(s.perfect, isFalse);
      expect(
        s.index,
        QuizConfig.lives - 1,
        reason: 'two questions never asked',
      );
      expect(s.missed, hasLength(QuizConfig.lives));
      expect(s.next, throwsStateError);
    });

    test('is not finished until the current question is answered', () {
      final s = QuizSession([qs.first], maxLives: 1);
      expect(s.finished, isFalse);
      s.answer(2);
      expect(s.finished, isTrue);
    });

    test('combo carries across questions', () {
      final s = QuizSession(qs);
      final combos = <int>[];
      for (var i = 0; i < 3; i++) {
        combos.add(s.answer(0).combo);
        s.next();
      }
      combos.add(s.answer(1).combo);

      expect(combos, [1, 2, 3, 0]);
    });
  });
}
