import 'quiz_generator.dart';

/// What one answer did.
class AnswerOutcome {
  const AnswerOutcome({
    required this.correct,
    required this.combo,
    required this.livesLeft,
    required this.correctIndex,
    required this.finished,
  });

  final bool correct;

  /// Run of correct answers after this one (0 after a wrong answer).
  final int combo;
  final int livesLeft;
  final int correctIndex;

  /// True when this answer ended the round.
  final bool finished;
}

/// One round: walk through the questions, track lives and combo.
///
/// Pure Dart (no Flutter), so the rules are easy to test. The round ends when
/// the last question is answered or the player runs out of lives.
class QuizSession {
  QuizSession(this.questions, {this.maxLives = QuizConfig.lives})
    : assert(questions.isNotEmpty),
      _lives = maxLives;

  final List<QuizQuestion> questions;
  final int maxLives;

  int _index = 0;
  int _lives;
  int _combo = 0;
  int _bestCombo = 0;
  int _correct = 0;
  int? _picked;

  /// Questions answered wrongly, in order. They are fed back into review.
  final List<QuizQuestion> missed = [];

  QuizQuestion get current => questions[_index];

  /// 0-based position of the current question.
  int get index => _index;
  int get total => questions.length;
  int get lives => _lives;
  int get combo => _combo;
  int get bestCombo => _bestCombo;
  int get correctCount => _correct;

  /// The option chosen for the current question, or null if unanswered.
  int? get picked => _picked;
  bool get answered => _picked != null;

  /// The round is over: out of lives, or the last question was answered.
  bool get finished => answered && (_lives == 0 || _index == total - 1);

  /// Every question was answered correctly.
  bool get perfect => finished && _correct == total;

  AnswerOutcome answer(int optionIndex) {
    if (answered) throw StateError('This question was already answered.');
    if (optionIndex < 0 || optionIndex >= current.options.length) {
      throw RangeError.index(optionIndex, current.options);
    }

    _picked = optionIndex;
    final correct = optionIndex == current.correctIndex;
    if (correct) {
      _correct++;
      _combo++;
      if (_combo > _bestCombo) _bestCombo = _combo;
    } else {
      _combo = 0;
      _lives--;
      missed.add(current);
    }

    return AnswerOutcome(
      correct: correct,
      combo: _combo,
      livesLeft: _lives,
      correctIndex: current.correctIndex,
      finished: finished,
    );
  }

  /// Moves to the next question. Only valid after answering, mid-round.
  void next() {
    if (!answered) throw StateError('Answer the question first.');
    if (finished) throw StateError('The round is over.');
    _index++;
    _picked = null;
  }
}
