import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/dummy_data.dart';
import '../social/identity.dart';
import '../social/social_store.dart';
import '../state/badges.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import 'ranking_screen.dart' show MyCodeCard;

/// "나" tab: level, stats, the level journey, badges and friend code.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _editIdentity(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const IdentitySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final social = SocialScope.of(context);

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  _ProfileCard(
                    progress: progress,
                    social: social,
                    onEdit: () => _editIdentity(context),
                  ),
                  const SizedBox(height: 16),
                  _StatsGrid(progress: progress),
                  const SectionHeading('나의 여정 🗺️'),
                  _Journey(progress: progress),
                  SectionHeading(
                    '배지 🏅',
                    trailing:
                        '${progress.badgeCount} / ${progress.badges.length}',
                  ),
                  _BadgeGrid(progress: progress),
                  const SectionHeading('친구 초대 💌'),
                  MyCodeCard(
                    code: social.identity.code,
                    invite: social.inviteText,
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

// ---- header card -----------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.progress,
    required this.social,
    required this.onEdit,
  });

  final ProgressStore progress;
  final SocialStore social;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final level = progress.level;
    final next = progress.nextLevel;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress.levelProgress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.star,
                          ),
                        ),
                      ),
                    ),
                    PopIn(
                      child: AvatarBubble(
                        emoji: social.identity.avatar,
                        size: 70,
                        background: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      social.identity.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.emoji} Lv.${progress.levelNumber}  ${level.name}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
              PressableScale(
                onTap: onEdit,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ProgressBar(
            value: progress.levelProgress,
            fill: AppColors.star,
            track: Colors.white.withValues(alpha: 0.25),
            height: 12,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${progress.xp} XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                next == null
                    ? '최고 레벨이에요! 👑'
                    : '다음 레벨까지 ${next.minXp - progress.xp} XP',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- stats -----------------------------------------------------------------

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(
        emoji: '🔥',
        value: '${progress.currentStreak}일',
        label: '연속 접속\n최고 ${progress.bestStreak}일',
      ),
      _StatTile(
        emoji: '📚',
        value: '${progress.completedCount} / ${knowledgeItems.length}',
        label: '알게 된 상식',
      ),
      _StatTile(emoji: '⭐', value: '${progress.weeklyXp}', label: '이번 주 XP'),
      _StatTile(
        emoji: '🏅',
        value: '${progress.badgeCount} / ${progress.badges.length}',
        label: '모은 배지',
      ),
    ];

    // Fixed tile height (not an aspect ratio) so content never gets squeezed
    // on narrow screens or with large system fonts.
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 92,
      ),
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFE7DD), width: 2),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(emoji, style: const TextStyle(fontSize: 30, height: 1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- journey ---------------------------------------------------------------

/// A vertical road of levels: done, current (with progress) and locked.
class _Journey extends StatelessWidget {
  const _Journey({required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final current = progress.levelNumber - 1;

    return Column(
      children: [
        for (var i = 0; i < levels.length; i++)
          _JourneyStep(
            level: levels[i],
            number: i + 1,
            isLast: i == levels.length - 1,
            state: i < current
                ? _StepState.done
                : (i == current ? _StepState.current : _StepState.locked),
            progress: progress,
          ),
      ],
    );
  }
}

enum _StepState { done, current, locked }

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({
    required this.level,
    required this.number,
    required this.isLast,
    required this.state,
    required this.progress,
  });

  final Level level;
  final int number;
  final bool isLast;
  final _StepState state;
  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final current = state == _StepState.current;
    final locked = state == _StepState.locked;

    // Fill of the road segment leading to the next level.
    final segment = done ? 1.0 : (current ? progress.levelProgress : 0.0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked
                        ? const Color(0xFFEDE9F5)
                        : (done ? AppColors.purple : Colors.white),
                    border: Border.all(
                      color: locked
                          ? const Color(0xFFD9D3E8)
                          : AppColors.purple,
                      width: current ? 4 : 3,
                    ),
                    boxShadow: current
                        ? [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                  child: ExcludeSemantics(
                    child: locked
                        ? const Text(
                            '🔒',
                            style: TextStyle(fontSize: 18, height: 1),
                          )
                        : done
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            level.emoji,
                            style: const TextStyle(fontSize: 22, height: 1),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 6,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3DEF0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.topCenter,
                      // A zero heightFactor makes the intrinsic-height pass
                      // divide by zero, so only draw the fill when there is
                      // something to fill.
                      child: segment > 0
                          ? FractionallySizedBox(
                              heightFactor: segment.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.purple,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: current ? const Color(0xFFF1ECFF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: current ? AppColors.purple : const Color(0xFFEFE7DD),
                    width: 2,
                  ),
                ),
                child: Opacity(
                  opacity: locked ? 0.55 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Lv.$number  ${level.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          if (current)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '현재',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        number == 1 ? '여기서 시작!' : '${level.minXp} XP 달성',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- badges ----------------------------------------------------------------

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.progress});

  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 128,
      ),
      children: [
        for (final badge in progress.badges)
          _BadgeTile(
            badge: badge,
            unlocked: progress.hasBadge(badge.id),
            value: progress.badgeProgress(badge),
          ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.unlocked,
    required this.value,
  });

  final AppBadge badge;
  final bool unlocked;
  final int value;

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => BadgeDialog(
        badge: badge,
        unlocked: unlocked,
        progressText: unlocked ? null : '$value / ${badge.goal}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: unlocked ? null : const Color(0xFFF3F0F8),
          gradient: unlocked
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE08A), Color(0xFFFFB84D)],
                )
              : null,
          border: Border.all(
            color: unlocked ? const Color(0xFFFFB84D) : const Color(0xFFE3DEF0),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.28,
              child: ExcludeSemantics(
                child: Text(
                  badge.emoji,
                  style: const TextStyle(fontSize: 34, height: 1.1),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: unlocked ? AppColors.ink : AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            if (unlocked)
              const Text(
                '획득!',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF9A5B00),
                ),
              )
            else ...[
              ProgressBar(
                value: value / badge.goal,
                fill: AppColors.purple,
                track: const Color(0xFFE3DEF0),
                height: 6,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value / ${badge.goal}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Used both from the badge wall (tap) and the feed (new badge pop-up).
class BadgeDialog extends StatelessWidget {
  const BadgeDialog({
    super.key,
    required this.badge,
    required this.unlocked,
    this.progressText,
    this.celebrate = false,
  });

  final AppBadge badge;
  final bool unlocked;
  final String? progressText;

  /// True when shown the moment the badge is earned.
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: PopIn(
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                celebrate ? 'NEW BADGE!' : (unlocked ? '획득한 배지' : '아직 잠겨 있어요'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: celebrate ? 3 : 0.5,
                  color: celebrate ? AppColors.pink : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: unlocked ? 1 : 0.3,
                child: Text(badge.emoji, style: const TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              if (progressText != null) ...[
                const SizedBox(height: 10),
                Text(
                  '진행도 $progressText',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple,
                  ),
                ),
              ],
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
                    '확인',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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

// ---- identity editor -------------------------------------------------------

/// Pick an avatar and nickname words. No free text on purpose.
class IdentitySheet extends StatelessWidget {
  const IdentitySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);
    final id = social.identity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  AvatarBubble(emoji: id.avatar, size: 84),
                  const SizedBox(height: 8),
                  Text(
                    id.nickname,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '캐릭터',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < animals.length; i++)
                  PressableScale(
                    onTap: () => social.updateIdentity(animalIndex: i),
                    child: AvatarBubble(
                      emoji: animals[i].emoji,
                      size: 52,
                      highlight: i == id.animalIndex,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '꾸밈말',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < adjectives.length; i++)
                  ChoiceChip(
                    label: Text(
                      adjectives[i],
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    selected: i == id.adjectiveIndex,
                    onSelected: (_) => social.updateIdentity(adjectiveIndex: i),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: social.rerollIdentity,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      '🎲 랜덤',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      '완료',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
