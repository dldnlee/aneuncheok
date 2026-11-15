import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dummy_data.dart';
import '../models/category.dart';
import '../models/knowledge_item.dart';
import '../quiz/quiz_generator.dart';
import '../quiz/quiz_session.dart';
import '../social/social_store.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import 'profile_screen.dart' show BadgeDialog;

/// A replayable round of "which topic is this explanation about?" built from
/// the cards the player has already learned.
///
/// Ten questions, three hearts. Right answers pay XP (more for a combo, up to
/// a daily cap); wrong answers cost a heart and put the card back into review.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.questions, this.random});

  /// Fixed questions, for tests. Normally they are generated from the cards
  /// the player has learned.
  final List<QuizQuestion>? questions;

  /// Source of randomness, so tests can be deterministic.
  final math.Random? random;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _XpFloat {
  _XpFloat(this.id, this.text);

  final int id;
  final String text;
}

class _QuizScreenState extends State<QuizScreen> {
  late final ProgressStore _store;
  late final SocialStore _social;
  final _confetti = GlobalKey<ConfettiLayerState>();
  late final math.Random _random = widget.random ?? math.Random();

  QuizSession? _session;
  bool _showResult = false;
  int _roundXp = 0;
  int _previousBest = 0;

  /// Bumped on every wrong answer so the picked button shakes again.
  int _shake = 0;
  final List<_XpFloat> _floats = [];
  int _floatSeq = 0;

  final List<Level> _pendingLevels = [];
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _store = ProgressScope.read(context);
    _social = SocialScope.read(context);
    _startRound();
  }

  @override
  void dispose() {
    // Let friends see what I just earned.
    _social.publishMine();
    super.dispose();
  }

  // ---- round flow -------------------------------------------------------

  List<QuizQuestion> _generate() {
    final pool = [
      for (final item in knowledgeItems)
        if (_store.isCompleted(item.id)) item,
    ];
    // Cards the player admitted not knowing are asked more often.
    final priority = {
      for (final item in pool)
        if (_store.reactionFor(item.id) == true) item.id,
    };
    return buildQuiz(
      pool: pool,
      all: knowledgeItems,
      random: _random,
      priorityIds: priority,
    );
  }

  void _startRound() {
    final questions = widget.questions ?? _generate();
    _session = questions.isEmpty ? null : QuizSession(questions);
    _showResult = false;
    _roundXp = 0;
    _previousBest = _store.bestQuizScore;
    _floats.clear();
  }

  void _pick(int option) {
    final session = _session!;
    if (session.answered) return;

    final question = session.current;
    final outcome = session.answer(option);
    final result = _store.quizAnswer(
      question.item.id,
      correct: outcome.correct,
      combo: outcome.combo,
    );
    _roundXp += result.xpGained;

    if (outcome.correct) {
      HapticFeedback.mediumImpact();
      _confetti.currentState?.burst(
        origin: const Offset(0.5, 0.7),
        strength: outcome.combo >= 3 ? 0.9 : 0.5,
      );
      if (result.xpGained > 0) _addFloat('+${result.xpGained} XP');
    } else {
      HapticFeedback.heavyImpact();
      _shake++;
    }

    final level = result.leveledUpTo;
    if (level != null) _pendingLevels.add(level);

    if (outcome.finished) {
      final done = _store.quizRoundFinished(
        correct: session.correctCount,
        perfect: session.perfect,
      );
      _roundXp += done.xpGained;
      if (done.xpGained > 0) _addFloat('+${done.xpGained} XP 만점 보너스!');
      if (session.perfect) {
        _confetti.currentState?.burst(
          origin: const Offset(0.5, 0.5),
          strength: 1.8,
        );
      }
      final up = done.leveledUpTo;
      if (up != null) _pendingLevels.add(up);
    }

    setState(() {});
    _celebrate();
  }

  void _next() {
    final session = _session!;
    if (!session.answered) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (session.finished) {
        _showResult = true;
      } else {
        session.next();
      }
    });
  }

  void _again() {
    HapticFeedback.mediumImpact();
    setState(_startRound);
  }

  void _addFloat(String text) {
    setState(() => _floats.add(_XpFloat(_floatSeq++, text)));
  }

  /// Shows pending level-ups and new badges one after another.
  Future<void> _celebrate() async {
    if (_celebrating) return;
    _celebrating = true;
    try {
      while (true) {
        if (!mounted) return;
        if (_pendingLevels.isNotEmpty) {
          _confetti.currentState?.burst(strength: 1.6);
          await showLevelUpDialog(context, _pendingLevels.removeAt(0));
          continue;
        }
        final badges = _store.drainNewBadges();
        if (badges.isEmpty) break;
        for (final badge in badges) {
          if (!mounted) return;
          _confetti.currentState?.burst(strength: 1.4);
          HapticFeedback.heavyImpact();
          await showDialog<void>(
            context: context,
            builder: (_) =>
                BadgeDialog(badge: badge, unlocked: true, celebrate: true),
          );
        }
      }
    } finally {
      _celebrating = false;
    }
  }

  // ---- build ------------------------------------------------------------

  Category _categoryOf(KnowledgeItem item) => categories.firstWhere(
    (c) => c.id == item.categoryId,
    orElse: () => categories.first,
  );

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final category = session == null
        ? categories.first
        : _categoryOf(session.current.item);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // The background takes the colors of the card being asked about.
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _showResult || session == null
                        ? const [AppColors.purpleLight, AppColors.purple]
                        : category.gradient,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: -70,
              right: -80,
              child: Bubble(size: 280, opacity: 0.1),
            ),
            const Positioned(
              bottom: 120,
              left: -100,
              child: Bubble(size: 250, opacity: 0.07),
            ),
            SafeArea(
              child: session == null
                  ? _Empty(onBack: () => Navigator.pop(context))
                  : _showResult
                  ? _Result(
                      session: session,
                      store: _store,
                      xp: _roundXp,
                      newBest: session.correctCount > _previousBest,
                      onAgain: _again,
                      onHome: () => Navigator.pop(context),
                    )
                  : _Question(
                      session: session,
                      category: category,
                      shake: _shake,
                      onPick: _pick,
                      onNext: _next,
                      onBack: () => Navigator.pop(context),
                    ),
            ),
            Positioned.fill(child: ConfettiLayer(key: _confetti)),
            for (final f in _floats)
              _XpFloatView(
                key: ValueKey(f.id),
                text: f.text,
                onDone: () {
                  if (mounted) setState(() => _floats.remove(f));
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ---- the question ----------------------------------------------------------

class _Question extends StatelessWidget {
  const _Question({
    required this.session,
    required this.category,
    required this.shake,
    required this.onPick,
    required this.onNext,
    required this.onBack,
  });

  final QuizSession session;
  final Category category;
  final int shake;
  final ValueChanged<int> onPick;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    // Short screens drop the big sticker and tighten spacing so the answer
    // buttons never leave the screen.
    final compact = height < 700;
    final tiny = height < 600;
    final question = session.current;
    final answered = session.answered;

    return Column(
      children: [
        _TopBar(session: session, onBack: onBack),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!tiny) ...[
                        _MysterySticker(
                          // A new question gets a fresh ❓.
                          key: ValueKey('${session.index}-$answered'),
                          emoji: answered ? question.item.emoji : null,
                          size: compact ? 60 : 96,
                        ),
                        SizedBox(height: compact ? 8 : 16),
                      ],
                      const Text(
                        '이 설명은 어떤 상식일까요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 14),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 14 : 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          question.masked,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 15.5 : 17.5,
                            height: 1.55,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, compact ? 12 : 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < question.options.length; i++) ...[
                _Option(
                  label: question.options[i].title,
                  state: _stateOf(i),
                  compact: compact,
                  shake: i == session.picked && i != question.correctIndex
                      ? shake
                      : 0,
                  onTap: answered ? null : () => onPick(i),
                ),
                SizedBox(height: compact ? 8 : 10),
              ],
              // Always reserves its height, so nothing jumps when it appears.
              SizedBox(
                height: compact ? 50 : 56,
                child: AnimatedOpacity(
                  opacity: answered ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !answered,
                    child: _NextButton(
                      label: session.finished ? '결과 보기' : '다음 문제 →',
                      accent: category.colorDark,
                      onTap: onNext,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _OptionState _stateOf(int i) {
    if (!session.answered) return _OptionState.idle;
    if (i == session.current.correctIndex) return _OptionState.correct;
    if (i == session.picked) return _OptionState.wrong;
    return _OptionState.dimmed;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.session, required this.onBack});

  final QuizSession session;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // While a question is open it counts as "in progress", so the bar shows
    // how far through the round the player is.
    final shown = session.index + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              PressableScale(
                onTap: onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProgressBar(
                  value: shown / session.total,
                  fill: Colors.white,
                  track: Colors.black.withValues(alpha: 0.2),
                  height: 8,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$shown / ${session.total}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < session.maxLives; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AnimatedScale(
                    scale: i < session.lives ? 1 : 0.8,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      i < session.lives
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 26,
                      color: i < session.lives
                          ? const Color(0xFFFFE3EC)
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: session.combo >= 2
                    ? Container(
                        key: ValueKey(session.combo),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.star,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '🔥 ${session.combo} 콤보',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('none'), height: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A big ❓ that turns into the card's emoji once the question is answered.
class _MysterySticker extends StatelessWidget {
  const _MysterySticker({super.key, required this.emoji, required this.size});

  final String? emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 3,
          ),
        ),
        child: ExcludeSemantics(
          child: Text(
            emoji ?? '❓',
            style: TextStyle(fontSize: size * 0.52, height: 1),
          ),
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.state,
    required this.compact,
    required this.shake,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final bool compact;

  /// Non-zero for the wrong answer that was just picked.
  final int shake;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final correct = state == _OptionState.correct;
    final wrong = state == _OptionState.wrong;
    final dimmed = state == _OptionState.dimmed;

    final Color background = correct
        ? Colors.white
        : wrong
        ? const Color(0xFF7F1D1D)
        : Colors.white.withValues(alpha: dimmed ? 0.1 : 0.22);
    final Color textColor = correct
        ? const Color(0xFF047857)
        : Colors.white.withValues(alpha: dimmed ? 0.65 : 1);

    Widget button = PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: BoxConstraints(minHeight: compact ? 48 : 54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(compact ? 24 : 27),
          border: Border.all(
            color: Colors.white.withValues(alpha: correct || wrong ? 1 : 0.5),
            width: 2.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 15 : 16.5,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
            if (correct || wrong) ...[
              const SizedBox(width: 8),
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 22,
                color: correct ? const Color(0xFF059669) : Colors.white,
              ),
            ],
          ],
        ),
      ),
    );

    if (shake > 0 && !reduceMotion(context)) {
      button = TweenAnimationBuilder<double>(
        key: ValueKey('shake-$shake'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        builder: (context, t, child) => Transform.translate(
          offset: Offset(math.sin(t * math.pi * 6) * 9 * (1 - t), 0),
          child: child,
        ),
        child: button,
      );
    }
    return button;
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      ),
    );
  }
}

/// A "+5 XP" chip that floats up and fades out.
class _XpFloatView extends StatelessWidget {
  const _XpFloatView({super.key, required this.text, required this.onDone});

  final String text;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          onEnd: onDone,
          builder: (context, t, _) {
            final rise = -60 * Curves.easeOut.transform(t);
            final fade = 1 - ((t - 0.55) / 0.45).clamp(0, 1);
            return Align(
              alignment: const Alignment(0, -0.15),
              child: Transform.translate(
                offset: Offset(0, rise),
                child: Opacity(
                  opacity: fade.toDouble(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.star,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---- the result ------------------------------------------------------------

class _Result extends StatelessWidget {
  const _Result({
    required this.session,
    required this.store,
    required this.xp,
    required this.newBest,
    required this.onAgain,
    required this.onHome,
  });

  final QuizSession session;
  final ProgressStore store;
  final int xp;
  final bool newBest;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final perfect = session.perfect;
    final outOfHearts = session.lives == 0;
    final emoji = perfect
        ? '🏆'
        : outOfHearts
        ? '💪'
        : '🎉';
    final message = perfect
        ? '만점이에요! 대단해요 🎊'
        : outOfHearts
        ? '하트를 모두 썼어요. 다시 도전해 볼까요?'
        : '잘했어요! 한 번 더 해볼까요?';

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 36),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopIn(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 84),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${session.correctCount} / ${session.total} 정답!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (xp > 0)
                              _Chip('⭐ +$xp XP', filled: true)
                            else if (store.quizXpLeftToday == 0)
                              const _Chip('✅ 오늘 퀴즈 XP를 다 받았어요'),
                            if (newBest && session.correctCount > 0)
                              const _Chip('🎖️ 새 기록!'),
                            if (session.bestCombo >= 2)
                              _Chip('🔥 최고 ${session.bestCombo} 콤보'),
                          ],
                        ),
                        if (session.missed.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '틀린 상식은 복습에 추가했어요 🧠',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final q in session.missed.take(5))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${q.item.emoji ?? ''} ${q.item.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (session.missed.length > 5)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '… 외 ${session.missed.length - 5}개',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ResultButton(label: '🔄 한 번 더', filled: true, onTap: onAgain),
                const SizedBox(height: 12),
                _ResultButton(label: '🏠 홈으로', onTap: onHome),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.star : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w900,
          color: filled ? AppColors.ink : Colors.white,
        ),
      ),
    );
  }
}

class _ResultButton extends StatelessWidget {
  const _ResultButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: filled ? AppColors.purple : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧩', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 12),
          const Text(
            '아직 퀴즈를 만들 상식이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _ResultButton(label: '🏠 홈으로', filled: true, onTap: onBack),
        ],
      ),
    );
  }
}
