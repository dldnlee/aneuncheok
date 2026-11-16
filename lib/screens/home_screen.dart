import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dummy_data.dart';
import '../models/category.dart';
import '../models/knowledge_item.dart';
import '../social/social_store.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';
import 'knowledge_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenRanking});

  /// Switches to the ranking tab (used by the rank teaser card).
  final VoidCallback? onOpenRanking;

  /// Cards the user has not reacted to yet come first, so the feed always
  /// opens on something new.
  static List<KnowledgeItem> _freshFirst(
    List<KnowledgeItem> items,
    ProgressStore store,
  ) => [
    ...items.where((i) => !store.isCompleted(i.id)),
    ...items.where((i) => store.isCompleted(i.id)),
  ];

  void _openCategory(BuildContext context, Category category) {
    final store = ProgressScope.read(context);
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      fadeSlideRoute(
        KnowledgeScreen(
          items: _freshFirst(getItemsByCategory(category.id), store),
          category: category,
        ),
      ),
    );
  }

  void _openShuffle(BuildContext context) {
    final store = ProgressScope.read(context);
    HapticFeedback.mediumImpact();
    final shuffled = List.of(knowledgeItems)..shuffle();
    Navigator.push(
      context,
      fadeSlideRoute(KnowledgeScreen(items: _freshFirst(shuffled, store))),
    );
  }

  void _openSaved(BuildContext context) {
    final store = ProgressScope.read(context);
    final saved = knowledgeItems.where((i) => store.isSaved(i.id)).toList();
    if (saved.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('아직 저장한 상식이 없어요. 카드를 두 번 탭해 보세요 ❤️')),
        );
      return;
    }
    Navigator.push(
      context,
      fadeSlideRoute(KnowledgeScreen(items: saved, label: '저장한 상식')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressScope.of(context);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      child: _Header(
                        store: store,
                        onSavedTap: () => _openSaved(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: _HeroCard(store: store),
                    ),
                  ),
                  if (onOpenRanking != null)
                    SliverToBoxAdapter(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: _RankTeaser(onTap: onOpenRanking!),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: _ShuffleButton(onTap: () => _openShuffle(context)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _SectionTitle()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final ids = getItemsByCategory(
                          category.id,
                        ).map((i) => i.id);
                        return _CategoryCard(
                          category: category,
                          index: index,
                          done: store.completedIn(ids),
                          total: ids.length,
                          onTap: () => _openCategory(context, category),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 5) return '🌙 늦은 밤이에요';
  if (h < 12) return '☀️ 좋은 아침이에요';
  if (h < 18) return '👋 안녕하세요';
  return '🌙 좋은 저녁이에요';
}

class _Header extends StatelessWidget {
  const _Header({required this.store, required this.onSavedTap});

  final ProgressStore store;
  final VoidCallback onSavedTap;

  @override
  Widget build(BuildContext context) {
    final streak = store.currentStreak;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [AppColors.purple, AppColors.pink],
                  ).createShader(rect),
                  child: const Text(
                    '아는척',
                    style: TextStyle(
                      fontSize: 36,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StatChip(
            emoji: '🔥',
            value: '$streak',
            semanticsLabel: '연속 $streak일',
            highlighted: store.activeToday,
            wiggle: store.activeToday,
          ),
          const SizedBox(width: 8),
          _StatChip(
            emoji: '❤️',
            value: '${store.savedCount}',
            semanticsLabel: '저장한 상식 ${store.savedCount}개',
            onTap: onSavedTap,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.emoji,
    required this.value,
    required this.semanticsLabel,
    this.onTap,
    this.highlighted = false,
    this.wiggle = false,
  });

  final String emoji;
  final String value;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool wiggle;

  @override
  Widget build(BuildContext context) {
    Widget icon = Text(emoji, style: const TextStyle(fontSize: 20, height: 1));
    if (wiggle) {
      icon = Loop(
        duration: const Duration(milliseconds: 700),
        builder: (context, t) => Transform.rotate(
          angle: (t - 0.5) * 0.4,
          child: Text(emoji, style: const TextStyle(fontSize: 20, height: 1)),
        ),
      );
    }

    final chip = Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: highlighted ? const Color(0xFFFFEBD6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted ? AppColors.orange : const Color(0xFFEFE7DD),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );

    return onTap == null ? chip : PressableScale(onTap: onTap, child: chip);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final level = store.level;
    final next = store.nextLevel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purpleLight, AppColors.purple],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              const Positioned(right: -30, top: -40, child: Bubble(size: 150)),
              const Positioned(
                left: -26,
                bottom: -46,
                child: Bubble(size: 120, opacity: 0.09),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        PopIn(
                          child: Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              level.emoji,
                              style: const TextStyle(fontSize: 32, height: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lv.${store.levelNumber}  ${level.name}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _Bar(
                                value: store.levelProgress,
                                fill: AppColors.star,
                                track: Colors.white.withValues(alpha: 0.25),
                                height: 10,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                next == null
                                    ? '최고 레벨이에요! 👑'
                                    : '다음 레벨까지 ${next.minXp - store.xp} XP',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _GoalRow(store: store),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final viewed = store.todayViewed;
    final reached = store.goalReached;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            // Scales down instead of wrapping on narrow screens or with
            // large system font sizes.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                reached ? '🎉 목표 달성!' : '🎯 오늘의 목표',
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          for (var i = 0; i < ProgressStore.dailyGoal; i++)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: AnimatedScale(
                scale: i < viewed ? 1.12 : 0.9,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  Icons.star_rounded,
                  size: 24,
                  color: i < viewed
                      ? AppColors.star
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Text(
            '${viewed.clamp(0, ProgressStore.dailyGoal)}/${ProgressStore.dailyGoal}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.fill,
    required this.track,
    required this.height,
  });

  final double value;
  final Color fill;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: track,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Where do I stand among friends?" - the nudge that links to the ranking.
class _RankTeaser extends StatelessWidget {
  const _RankTeaser({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);
    // Nothing to compare yet (not loaded, or no friends): stay out of the way.
    if (!social.loaded || !social.hasFriends) return const SizedBox.shrink();

    final rank = social.friendRank!;
    final rival = social.rivalAbove;
    final subtitle = rival == null
        ? '지금 친구들 중 1등이에요! 👑'
        : '${rival.profile.avatar} ${rival.profile.nickname}님까지 ${social.xpToPass(rival.profile)} XP';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.97,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEFE7DD), width: 2),
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 32, height: 1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '친구 중 $rank위',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.96,
        child: Loop(
          duration: const Duration(milliseconds: 1400),
          builder: (context, t) => Transform.scale(
            scale: 1 + 0.02 * t,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [AppColors.orange, AppColors.pink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pink.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Transform.rotate(
                    angle: (t - 0.5) * 0.5,
                    child: const Text(
                      '🎲',
                      style: TextStyle(fontSize: 38, height: 1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '랜덤 상식',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${knowledgeItems.length}개 중에 아무거나 뽑아요!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 24, 20, 14),
      child: Text(
        '어떤 상식이 궁금해요? 🤔',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.index,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final Category category;
  final int index;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && done >= total;

    return FadeSlideIn(
      delay: Duration(milliseconds: 220 + index * 70),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: category.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: category.colorDark.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                const Positioned(
                  right: -28,
                  top: -28,
                  child: Bubble(size: 120, opacity: 0.14),
                ),
                const Positioned(
                  left: -24,
                  bottom: -34,
                  child: Bubble(size: 100, opacity: 0.1),
                ),
                Positioned(
                  right: 14,
                  top: 46,
                  child: Transform.rotate(
                    angle: index.isEven ? -0.14 : 0.14,
                    child: Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 62, height: 1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (complete)
                        const Text(
                          '✅ 모두 알았어요!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        _Bar(
                          value: total == 0 ? 0 : done / total,
                          fill: Colors.white,
                          track: Colors.black.withValues(alpha: 0.18),
                          height: 8,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$done / $total 알았어요',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
