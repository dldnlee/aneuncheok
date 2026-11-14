import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dummy_data.dart';
import '../models/category.dart';
import '../models/knowledge_item.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';

/// Full-screen vertical feed of knowledge cards.
///
/// With a [category] every card uses that category's colors. Without one
/// ("mixed" feed: shuffle, saved) each card uses its own category's colors.
class KnowledgeScreen extends StatefulWidget {
  KnowledgeScreen({super.key, required this.items, this.category, this.label})
    : assert(items.isNotEmpty);

  final List<KnowledgeItem> items;
  final Category? category;

  /// Optional title shown in the top bar (e.g. "저장한 상식").
  final String? label;

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
  final _pageController = PageController();
  final _confetti = GlobalKey<ConfettiLayerState>();

  int _page = 0;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onViewed(0);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ---- events ---------------------------------------------------------

  void _onViewed(int index) {
    if (index >= _items.length) return;
    final result = _store.recordView(_items[index].id);
    if (result.goalReached) {
      _showToast('🎯 오늘 목표 달성! 대단해요');
      _confetti.currentState?.burst(strength: 1.6);
      HapticFeedback.heavyImpact();
    } else if (result.streakIncreased) {
      _showToast('🔥 ${_store.currentStreak}일 연속! 멋져요');
    }
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    HapticFeedback.selectionClick();
    _onViewed(index);
  }

  void _react(KnowledgeItem item, {required bool newToMe}) {
    final result = _store.complete(item.id, newToMe: newToMe);
    HapticFeedback.mediumImpact();
    if (result.firstTime) {
      _confetti.currentState?.burst();
      _addPop(
        _PopKind.reward,
        newToMe ? '+1  새로 알았다! 🌟' : '+1  역시 알고 있었네! 😎',
      );
    }
    final level = result.leveledUpTo;
    if (level != null) _showLevelUp(level);
  }

  void _toggleSave(KnowledgeItem item) {
    final saved = _store.toggleSaved(item.id);
    HapticFeedback.lightImpact();
    if (saved) _addPop(_PopKind.heart, '');
  }

  void _doubleTapSave(KnowledgeItem item) {
    _store.save(item.id);
    HapticFeedback.lightImpact();
    _addPop(_PopKind.heart, '');
  }

  Future<void> _share(KnowledgeItem item) async {
    await Clipboard.setData(ClipboardData(text: item.shareText));
    if (!mounted) return;
    _showToast('📋 복사했어요! 친구한테 아는척 해보세요');
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

  void _showLevelUp(Level level) {
    final number = levels.indexOf(level) + 1;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: PopIn(
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 10),
                Text(level.emoji, style: const TextStyle(fontSize: 84)),
                const SizedBox(height: 8),
                Text(
                  level.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lv.$number 달성! 🎉',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      '계속하기',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
  });

  final KnowledgeItem item;
  final Category category;
  final ProgressStore store;
  final bool showCategory;
  final ValueChanged<bool> onReact;
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
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 72, 24, 18),
                      child: ListenableBuilder(
                        listenable: store,
                        builder: (context, _) => _buildContent(emoji),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String emoji) {
    final reaction = store.reactionFor(item.id);
    final saved = store.isSaved(item.id);

    return Column(
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
              _Sticker(emoji: emoji),
              const SizedBox(height: 20),
              if (showCategory) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${category.emoji} ${category.name}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FadeSlideIn(
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
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
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.6,
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
          ),
        ),
        const SizedBox(height: 14),
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
        const Spacer(flex: 2),
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
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Loop(
        duration: const Duration(milliseconds: 2200),
        builder: (context, t) => Transform.translate(
          offset: Offset(0, -7 * t),
          child: Container(
            width: 118,
            height: 118,
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
            child: Text(emoji, style: const TextStyle(fontSize: 62, height: 1)),
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
  const _SwipeHint({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    if (!done) {
      return Text(
        '어땠나요? 반응을 남겨보세요 👆',
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
        child: const Column(
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 30,
            ),
            Text(
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
    required this.onRestart,
    required this.onHome,
  });

  final ProgressStore store;
  final List<String> ids;
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
                      const Text(
                        '여기까지 다 봤어요!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$done / ${ids.length}개를 알아봤어요',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (streak > 0) ...[
                        const SizedBox(height: 14),
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
                      const SizedBox(height: 36),
                      _FinishButton(
                        label: '🔄 처음부터 다시',
                        filled: true,
                        onTap: onRestart,
                      ),
                      const SizedBox(height: 12),
                      _FinishButton(label: '🏠 홈으로', onTap: onHome),
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
