import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dummy_data.dart';
import '../models/category.dart';
import '../models/knowledge_item.dart';
import '../social/social_store.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/celebrations.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import 'profile_screen.dart' show BadgeDialog;

/// Full-screen vertical feed of knowledge cards.
///
/// With a [category] every card uses that category's colors. Without one
/// ("mixed" feed: shuffle, saved) each card uses its own category's colors.
class KnowledgeScreen extends StatefulWidget {
  KnowledgeScreen({
    super.key,
    required this.items,
    this.category,
    this.label,
    this.review = false,
  }) : assert(items.isNotEmpty);

  final List<KnowledgeItem> items;
  final Category? category;

  /// Optional title shown in the top bar (e.g. "저장한 상식").
  final String? label;

  /// Review mode: cards start with the answer hidden and are rated
  /// "기억나요" / "헷갈려요" instead of "몰랐어요" / "알고 있었어요".
  final bool review;

  bool get mixed => category == null;

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

enum _PopKind { heart, reward }

class _Pop {
  _Pop(this.id, this.kind, this.text);

  final int id;
  final _PopKind kind;
  final String text;
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  late final ProgressStore _store;
  late final SocialStore _social;
  final _pageController = PageController();
  final _confetti = GlobalKey<ConfettiLayerState>();

  int _page = 0;

  /// XP earned during this visit - shown on the finish screen.
  int _sessionXp = 0;

  /// Level-ups and badges wait here so dialogs show one at a time.
  final List<Level> _pendingLevels = [];
  bool _celebrating = false;

  // Review mode: which answers were revealed, and how each card was rated.
  final Set<String> _revealed = {};
  final Map<String, bool> _reviewAnswers = {};
  final Map<String, String> _reviewNotes = {};
  String _toastText = '';
  bool _toastVisible = false;
  Timer? _toastTimer;
  final List<_Pop> _pops = [];
  int _popSeq = 0;

  List<KnowledgeItem> get _items => widget.items;

  Category _categoryOf(KnowledgeItem item) =>
      widget.category ??
      categories.firstWhere(
        (c) => c.id == item.categoryId,
        orElse: () => categories.first,
      );

  @override
  void initState() {
    super.initState();
    _store = ProgressScope.read(context);
    _social = SocialScope.read(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onViewed(0);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _pageController.dispose();
    // Let friends see what I just earned.
    _social.publishMine();
    super.dispose();
  }

  // ---- events ---------------------------------------------------------

  void _onViewed(int index) {
    if (index >= _items.length) return;
    final result = _store.recordView(_items[index].id);
    _sessionXp += result.xpGained;

    if (result.goalReached) {
      _showToast('🎯 오늘 목표 달성! +${XpRewards.dailyGoal} XP');
      _confetti.currentState?.burst(strength: 1.6);
      HapticFeedback.heavyImpact();
    } else if (result.streakIncreased) {
      final bonus = XpRewards.streakBonus(_store.currentStreak);
      _showToast(
        bonus > 0
            ? '🔥 ${_store.currentStreak}일 연속! +$bonus XP'
            : '🔥 ${_store.currentStreak}일 연속! 멋져요',
      );
    }

    final level = result.leveledUpTo;
    if (level != null) _pendingLevels.add(level);
    _celebrate();
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    HapticFeedback.selectionClick();
    _onViewed(index);
  }

  void _react(KnowledgeItem item, {required bool newToMe}) {
    final result = _store.complete(item.id, newToMe: newToMe);
    _sessionXp += result.xpGained;
    HapticFeedback.mediumImpact();

    if (result.firstTime) {
      _confetti.currentState?.burst();
      _addPop(
        _PopKind.reward,
        newToMe
            ? '+${result.xpGained} XP  새로 알았다! 🌟'
            : '+${result.xpGained} XP  역시 알고 있었네! 😎',
      );
    }

    final mastered = result.masteredCategoryId;
    if (mastered != null) {
      final category = categories.firstWhere((c) => c.id == mastered);
      _showToast('🏆 ${category.name} 정복! +${XpRewards.categoryMastery} XP');
      _confetti.currentState?.burst(strength: 1.8);
      HapticFeedback.heavyImpact();
    }

    final level = result.leveledUpTo;
    if (level != null) _pendingLevels.add(level);
    _celebrate();
  }

  void _toggleSave(KnowledgeItem item) {
    final saved = _store.toggleSaved(item.id);
    HapticFeedback.lightImpact();
    if (saved) _addPop(_PopKind.heart, '');
    _celebrate();
  }

  void _doubleTapSave(KnowledgeItem item) {
    _store.save(item.id);
    HapticFeedback.lightImpact();
    _addPop(_PopKind.heart, '');
    _celebrate();
  }

  Future<void> _share(KnowledgeItem item) async {
    await Clipboard.setData(ClipboardData(text: item.shareText));
    if (!mounted) return;
    _store.recordShare();
    _showToast('📋 복사했어요! 친구한테 아는척 해보세요');
    _celebrate();
  }

  void _reveal(KnowledgeItem item) {
    HapticFeedback.selectionClick();
    setState(() => _revealed.add(item.id));
  }

  void _review(KnowledgeItem item, {required bool remembered}) {
    // One answer per card per session: the store also refuses a card that is
    // no longer due, so XP cannot be farmed by tapping again.
    if (_reviewAnswers.containsKey(item.id)) return;
    final result = _store.review(item.id, remembered: remembered);
    if (!result.applied) return;

    _sessionXp += result.xpGained;
    setState(() {
      _reviewAnswers[item.id] = remembered;
      _reviewNotes[item.id] = result.graduated
          ? '🎓 졸업! 이 상식은 이제 완전히 내 것이에요'
          : remembered
          ? '${result.nextInDays}일 뒤에 다시 만나요'
          : '내일 다시 만나요';
    });

    HapticFeedback.mediumImpact();
    if (remembered) {
      _confetti.currentState?.burst(strength: result.graduated ? 1.8 : 0.8);
      _addPop(_PopKind.reward, '+${result.xpGained} XP  기억났다! 🧠');
    } else {
      _addPop(_PopKind.reward, '괜찮아요, 내일 또 만나요 💪');
    }
    if (result.graduated) _showToast('🎓 졸업! 복습을 모두 마쳤어요');

    final level = result.leveledUpTo;
    if (level != null) _pendingLevels.add(level);
    _celebrate();
  }

  /// Shows pending level-ups and new badges one after another. Safe to call
  /// repeatedly: if it is already running, it picks up anything new when the
  /// current dialog closes.
  Future<void> _celebrate() async {
    if (_celebrating) return;
    _celebrating = true;
    try {
      while (mounted) {
        if (_pendingLevels.isNotEmpty) {
          await _showLevelUp(_pendingLevels.removeAt(0));
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

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() {
      _toastText = text;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _toastVisible = false);
    });
  }

  void _addPop(_PopKind kind, String text) {
    setState(() => _pops.add(_Pop(_popSeq++, kind, text)));
  }

  void _removePop(int id) {
    if (!mounted) return;
    setState(() => _pops.removeWhere((p) => p.id == id));
  }

  Future<void> _showLevelUp(Level level) {
    _confetti.currentState?.burst(strength: 1.6);
    return showLevelUpDialog(context, level);
  }

  // ---- build ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final total = _items.length;
    final shown = math.min(_page + 1, total);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: total + 1,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (index == total) {
                  return _FinishCard(
                    store: _store,
                    ids: _items.map((i) => i.id).toList(),
                    sessionXp: _sessionXp,
                    review: widget.review,
                    remembered: _reviewAnswers.values.where((v) => v).length,
                    again: _reviewAnswers.values.where((v) => !v).length,
                    onRestart: () => _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    ),
                    onHome: () => Navigator.pop(context),
                  );
                }
                final item = _items[index];
                return _KnowledgeCard(
                  item: item,
                  category: _categoryOf(item),
                  store: _store,
                  showCategory: widget.mixed,
                  onReact: (newToMe) => _react(item, newToMe: newToMe),
                  review: widget.review,
                  revealed: _revealed.contains(item.id),
                  reviewAnswer: _reviewAnswers[item.id],
                  reviewNote: _reviewNotes[item.id],
                  onReveal: () => _reveal(item),
                  onReview: (remembered) =>
                      _review(item, remembered: remembered),
                  onToggleSave: () => _toggleSave(item),
                  onDoubleTapSave: () => _doubleTapSave(item),
                  onShare: () => _share(item),
                );
              },
            ),
            _TopBar(
              progress: shown / total,
              counter: '$shown / $total',
              label: widget.label,
              onBack: () => Navigator.pop(context),
            ),
            _Toast(text: _toastText, visible: _toastVisible),
            Positioned.fill(child: ConfettiLayer(key: _confetti)),
            for (final pop in _pops)
              _PopView(
                key: ValueKey(pop.id),
                pop: pop,
                onDone: () => _removePop(pop.id),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- top bar & overlays ------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.counter,
    required this.onBack,
    this.label,
  });

  final double progress;
  final String counter;
  final String? label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 0),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Text(
                        label!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 8,
                        color: Colors.black.withValues(alpha: 0.2),
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => FractionallySizedBox(
                            widthFactor: v.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                  counter,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text, required this.visible});

  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                offset: visible ? Offset.zero : const Offset(0, -0.8),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: visible ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-shot floating effect: a big heart or a "+1" reward chip.
class _PopView extends StatelessWidget {
  const _PopView({super.key, required this.pop, required this.onDone});

  final _Pop pop;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isHeart = pop.kind == _PopKind.heart;

    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: isHeart ? 900 : 1400),
          onEnd: onDone,
          builder: (context, t, _) {
            if (isHeart) {
              final scale = Curves.easeOutBack.transform((t / 0.4).clamp(0, 1));
              final fade = 1 - ((t - 0.6) / 0.4).clamp(0, 1);
              return Center(
                child: Opacity(
                  opacity: fade.toDouble(),
                  child: Transform.scale(
                    scale: scale * 1.1,
                    child: const Text('❤️', style: TextStyle(fontSize: 120)),
                  ),
                ),
              );
            }
            // Anchored above the reaction buttons and floats up through the
            // empty gap, so it never covers the text or the save/copy row.
            final rise = -50 * Curves.easeOut.transform(t);
            final fade = 1 - ((t - 0.6) / 0.4).clamp(0, 1);
            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 170),
                child: Transform.translate(
                  offset: Offset(0, rise),
                  child: Opacity(
                    opacity: fade.toDouble(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.star,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        pop.text,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
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

// ---- cards -------------------------------------------------------------

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({
    required this.item,
    required this.category,
    required this.store,
    required this.showCategory,
    required this.onReact,
    required this.onToggleSave,
    required this.onDoubleTapSave,
    required this.onShare,
    this.review = false,
    this.revealed = false,
    this.reviewAnswer,
    this.reviewNote,
    this.onReveal,
    this.onReview,
  });

  final KnowledgeItem item;
  final Category category;
  final ProgressStore store;
  final bool showCategory;
  final ValueChanged<bool> onReact;

  /// Review mode: hide the answer until revealed, then rate how well it was
  /// remembered. [reviewAnswer] is the rating given this session (if any).
  final bool review;
  final bool revealed;
  final bool? reviewAnswer;
  final String? reviewNote;
  final VoidCallback? onReveal;
  final ValueChanged<bool>? onReview;
  final VoidCallback onToggleSave;
  final VoidCallback onDoubleTapSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final emoji = item.emoji ?? category.emoji;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: category.gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -70,
            right: -80,
            child: Bubble(size: 280, opacity: 0.1),
          ),
          const Positioned(
            bottom: 90,
            left: -100,
            child: Bubble(size: 250, opacity: 0.07),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => _buildContent(
                emoji,
                // Short screens get a smaller sticker and tighter text so a
                // typical card fits without scrolling.
                compact: MediaQuery.sizeOf(context).height < 700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String emoji, {required bool compact}) {
    final reaction = store.reactionFor(item.id);
    final saved = store.isSaved(item.id);
    final step = store.reviewStep(item.id);
    final stepLabel = !review
        ? null
        : store.isGraduated(item.id)
        ? '🎓 졸업!'
        : step == null
        ? null
        : '🧠 복습 $step/${ProgressStore.reviewSteps}단계';
    final hideAnswer = review && !revealed;

    // The reading area scrolls if it has to; the buttons below it never do,
    // so they stay reachable on small phones.
    final body = Column(
      children: [
        const Spacer(),
        // Double-tap-to-save lives on the reading area only. Wrapping the
        // buttons too would make Flutter hold the gesture arena for ~300 ms
        // and delay every button tap.
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: onDoubleTapSave,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Sticker(emoji: emoji, size: compact ? 84 : 118),
              SizedBox(height: compact ? 12 : 20),
              if (showCategory || stepLabel != null) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (showCategory)
                      _Pill('${category.emoji} ${category.name}'),
                    if (stepLabel != null) _Pill(stepLabel),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              FadeSlideIn(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 28 : 32,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              if (!hideAnswer) ...[
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.content,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 16.5 : 18,
                            height: compact ? 1.5 : 1.6,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (item.source != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '출처: ${item.source}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // The recall card is tappable, so it must sit outside the double-tap
        // area above: otherwise Flutter would wait ~300 ms before letting the
        // tap through.
        if (hideAnswer) ...[
          const SizedBox(height: 18),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _RecallCard(onTap: onReveal),
          ),
        ],
        const SizedBox(height: 14),
        if (!hideAnswer)
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniAction(
                  icon: saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: saved ? '저장됨' : '저장',
                  active: saved,
                  onTap: onToggleSave,
                ),
                const SizedBox(width: 10),
                _MiniAction(
                  icon: Icons.ios_share_rounded,
                  label: '복사',
                  onTap: onShare,
                ),
              ],
            ),
          ),
        const Spacer(),
      ],
    );

    final bottom = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (review) ...[
          if (hideAnswer)
            _ReactionButton(
              label: '👀 내용 확인하기',
              accent: category.colorDark,
              selected: true,
              dimmed: false,
              onTap: onReveal ?? () {},
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ReactionButton(
                    label: '😵 헷갈려요',
                    accent: category.colorDark,
                    selected: reviewAnswer == false,
                    dimmed: reviewAnswer == true,
                    onTap: () => onReview?.call(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ReactionButton(
                    label: '✅ 기억나요!',
                    accent: category.colorDark,
                    selected: reviewAnswer == true,
                    dimmed: reviewAnswer == false,
                    onTap: () => onReview?.call(true),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          _SwipeHint(
            done: reviewAnswer != null,
            note: reviewNote,
            height: 72,
            idleText: hideAnswer
                ? '먼저 떠올려 본 뒤에 눌러 보세요 🤔'
                : '얼마나 기억나는지 골라 주세요 👆',
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: _ReactionButton(
                  label: '🤯 몰랐어요!',
                  accent: category.colorDark,
                  selected: reaction == true,
                  dimmed: reaction == false,
                  onTap: () => onReact(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReactionButton(
                  label: '😎 알고 있었어요',
                  accent: category.colorDark,
                  selected: reaction == false,
                  dimmed: reaction == true,
                  onTap: () => onReact(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SwipeHint(done: reaction != null),
        ],
      ],
    );

    return Column(
      children: [
        Expanded(
          // The padding lives inside the scroll view so the floating sticker
          // is never clipped at the viewport edge.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 72, 24, 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0, constraints.maxHeight - 80),
                ),
                child: IntrinsicHeight(child: body),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: bottom,
        ),
      ],
    );
  }
}

/// Small translucent label ("생활", "복습 2/5단계").
class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Stands in for the answer in review mode until the player taps it.
class _RecallCard extends StatelessWidget {
  const _RecallCard({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Text('🤔', style: TextStyle(fontSize: 34, height: 1)),
            const SizedBox(height: 10),
            const Text(
              '이 상식, 기억나요?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '떠올려 본 뒤 눌러서 확인해요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.emoji, this.size = 118});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Loop(
        duration: const Duration(milliseconds: 2200),
        builder: (context, t) => Transform.translate(
          offset: Offset(0, -7 * t),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: size * 0.525, height: 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? AppColors.pink : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: active ? AppColors.ink : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.label,
    required this.accent,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 58,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: dimmed ? 0.1 : 0.2),
          borderRadius: BorderRadius.circular(29),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.55),
            width: 2.5,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: selected
                  ? accent
                  : Colors.white.withValues(alpha: dimmed ? 0.7 : 1),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.done,
    this.note,
    this.idleText = '어땠나요? 반응을 남겨보세요 👆',
    this.height = 50,
  });

  final bool done;

  /// Fixed height, so the card does not jump when the hint changes from one
  /// line to several (which would squeeze the reading area on small phones).
  final double height;

  /// Extra line shown above the swipe hint once answered (review mode).
  final String? note;

  /// Shown until the card has been answered.
  final String idleText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(alignment: Alignment.topCenter, child: _content()),
    );
  }

  Widget _content() {
    if (!done) {
      return Text(
        idleText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      );
    }
    return Loop(
      duration: const Duration(milliseconds: 800),
      builder: (context, t) => Transform.translate(
        offset: Offset(0, -6 * t),
        child: Column(
          children: [
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 30,
            ),
            if (note != null)
              Text(
                note!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.star,
                ),
              ),
            const Text(
              '위로 스와이프해서 다음 상식',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishCard extends StatelessWidget {
  const _FinishCard({
    required this.store,
    required this.ids,
    required this.sessionXp,
    required this.onRestart,
    required this.onHome,
    this.review = false,
    this.remembered = 0,
    this.again = 0,
  });

  final ProgressStore store;
  final List<String> ids;

  /// Review mode: a different title and summary, and no "start over".
  final bool review;
  final int remembered;
  final int again;

  /// XP earned during this visit.
  final int sessionXp;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purpleLight, AppColors.purple],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -70,
            right: -80,
            child: Bubble(size: 280, opacity: 0.1),
          ),
          const Positioned(
            bottom: 60,
            left: -100,
            child: Bubble(size: 250, opacity: 0.07),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ListenableBuilder(
                listenable: store,
                builder: (context, _) {
                  final done = store.completedIn(ids);
                  final streak = store.currentStreak;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PopIn(
                        child: Loop(
                          duration: const Duration(milliseconds: 1200),
                          builder: (context, t) => Transform.rotate(
                            angle: (t - 0.5) * 0.3,
                            child: const Text(
                              '🎉',
                              style: TextStyle(fontSize: 96),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        review ? '오늘 복습 끝!' : '여기까지 다 봤어요!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        review
                            ? '$remembered개 기억났어요${again > 0 ? ' · $again개는 내일 다시' : ''}'
                            : '$done / ${ids.length}개를 알아봤어요',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (sessionXp > 0) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.star,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⭐ 이번에 +$sessionXp XP 얻었어요!',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                      if (streak > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🔥 $streak일 연속 달성 중!',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Text(
                        '${store.level.emoji} Lv.${store.levelNumber}  ${store.level.name}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(
                        value: store.levelProgress,
                        fill: AppColors.star,
                        track: Colors.white.withValues(alpha: 0.25),
                        height: 12,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        store.nextLevel == null
                            ? '최고 레벨이에요! 👑'
                            : '다음 레벨까지 ${store.nextLevel!.minXp - store.xp} XP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 30),
                      if (!review) ...[
                        _FinishButton(
                          label: '🔄 처음부터 다시',
                          filled: true,
                          onTap: onRestart,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _FinishButton(
                        label: '🏠 홈으로',
                        filled: review,
                        onTap: onHome,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishButton extends StatelessWidget {
  const _FinishButton({
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
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(29),
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
