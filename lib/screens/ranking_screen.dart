import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../social/identity.dart';
import '../social/models.dart';
import '../social/social_store.dart';
import '../state/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';

/// Weekly leaderboard: friends or everyone, with head-to-head comparison.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  bool _global = false;

  void _openAddFriend() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => const AddFriendSheet(),
    );
  }

  void _openCompare(LeaderboardEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => CompareSheet(them: entry.profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);
    final progress = social.progress;
    final entries = _global ? social.globalEntries : social.friendEntries;
    final showEmptyFriends = !_global && social.loaded && !social.hasFriends;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: RefreshIndicator(
                onRefresh: social.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _Header(daysLeft: progress.daysLeftInWeek),
                          if (social.isDemo) const _DemoBanner(),
                          const SizedBox(height: 14),
                          _Tabs(
                            global: _global,
                            onChanged: (g) => setState(() => _global = g),
                          ),
                          const SizedBox(height: 14),
                          if (!social.loaded && social.loading)
                            const _Loading()
                          else if (!social.loaded && social.failed)
                            _ErrorCard(onRetry: social.refresh)
                          else ...[
                            if (showEmptyFriends)
                              _EmptyFriends(onAdd: _openAddFriend)
                            else ...[
                              _StandingBanner(global: _global),
                              const SizedBox(height: 18),
                              if (entries.length >= 3)
                                _Podium(entries: entries, onTap: _openCompare),
                              const SizedBox(height: 14),
                              for (final e in entries.skip(
                                entries.length >= 3 ? 3 : 0,
                              ))
                                _RankRow(
                                  entry: e,
                                  onTap: e.isMe ? null : () => _openCompare(e),
                                ),
                            ],
                            if (!_global && !showEmptyFriends) ...[
                              const SizedBox(height: 8),
                              _AddFriendButton(onTap: _openAddFriend),
                            ],
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- header & chrome -------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '랭킹 🏆',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
              height: 1.15,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE7DD), width: 2),
          ),
          child: Text(
            daysLeft <= 1 ? '⏳ 오늘 마감!' : '⏳ $daysLeft일 남음',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3C4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        '🧪 데모 모드예요. 실제 친구 대신 가상의 플레이어가 나와요.',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7A5B00),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.global, required this.onChanged});

  final bool global;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, VoidCallback onTap) => Expanded(
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          tab('👫 친구', !global, () => onChanged(false)),
          tab('🌍 전체', global, () => onChanged(true)),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 60),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE7DD), width: 2),
      ),
      child: Column(
        children: [
          const Text('😵', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text(
            '랭킹을 불러오지 못했어요',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEFE7DD), width: 2),
      ),
      child: Column(
        children: [
          const Text('🥲', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          const Text(
            '아직 친구가 없어요',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '친구 코드를 입력하면 누가 더 아는척 잘하는지\n바로 겨뤄볼 수 있어요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 18),
          _AddFriendButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.purpleLight, AppColors.purple],
          ),
        ),
        child: const Text(
          '➕ 친구 추가',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---- standing banner & podium ----------------------------------------------

class _StandingBanner extends StatelessWidget {
  const _StandingBanner({required this.global});

  final bool global;

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);
    final String title;
    final String subtitle;

    if (global) {
      final me = social.globalEntries.firstWhere((e) => e.isMe);
      final total = social.globalPlayers;
      final top = ((me.rank / total) * 100).ceil();
      title = '전체 ${me.rank}위 / $total명';
      subtitle = me.rank == 1
          ? '👑 지금 전체 1등이에요!'
          : '상위 $top% · 이번 주 ${me.profile.weeklyXp} XP';
    } else {
      final rank = social.friendRank;
      final rival = social.rivalAbove;
      title = rank == null ? '친구를 추가해 보세요' : '친구 중 $rank위';
      if (rival == null) {
        subtitle = '👑 친구들 중에서 1등이에요! 계속 지켜내요';
      } else {
        final need = social.xpToPass(rival.profile);
        final cards = (need / XpRewards.newToMe).ceil();
        subtitle =
            '${rival.profile.avatar} ${rival.profile.nickname}님까지 $need XP\n'
            '카드 $cards개면 따라잡아요! 💪';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.pink],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.onTap});

  final List<LeaderboardEntry> entries;
  final ValueChanged<LeaderboardEntry> onTap;

  @override
  Widget build(BuildContext context) {
    Widget column(LeaderboardEntry e, double height) => Expanded(
      child: _PodiumColumn(
        entry: e,
        height: height,
        onTap: e.isMe ? null : () => onTap(e),
      ),
    );

    // Visual order: 2nd, 1st, 3rd.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        column(entries[1], 78),
        const SizedBox(width: 8),
        column(entries[0], 108),
        const SizedBox(width: 8),
        column(entries[2], 58),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({required this.entry, required this.height, this.onTap});

  final LeaderboardEntry entry;
  final double height;
  final VoidCallback? onTap;

  static const _medals = [
    [Color(0xFFFFD43B), Color(0xFFFFA94D)], // gold
    [Color(0xFFCED4DA), Color(0xFF9AA3AD)], // silver
    [Color(0xFFFFB27A), Color(0xFFD9772F)], // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final p = entry.profile;
    final first = entry.rank == 1;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          first ? '👑' : ' ',
          style: const TextStyle(fontSize: 22, height: 1.1),
        ),
        AvatarBubble(
          emoji: p.avatar,
          size: first ? 66 : 54,
          highlight: entry.isMe,
        ),
        const SizedBox(height: 6),
        Text(
          entry.isMe ? '나' : p.nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
            color: entry.isMe ? AppColors.purple : AppColors.ink,
          ),
        ),
        Text(
          '${p.weeklyXp} XP',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _medals[entry.rank - 1],
            ),
          ),
          child: Text(
            '${entry.rank}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );

    return onTap == null
        ? column
        : PressableScale(onTap: onTap, pressedScale: 0.97, child: column);
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, this.onTap});

  final LeaderboardEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = entry.profile;
    final row = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isMe ? const Color(0xFFF1ECFF) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: entry.isMe ? AppColors.purple : const Color(0xFFEFE7DD),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          AvatarBubble(emoji: p.avatar, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMe ? '${p.nickname} (나)' : p.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Lv.${levelNumberForXp(p.totalXp)} · 🔥 ${p.streak}일',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.weeklyXp}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.purple,
                ),
              ),
              const Text(
                'XP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return onTap == null
        ? row
        : PressableScale(onTap: onTap, pressedScale: 0.98, child: row);
  }
}

// ---- add friend ------------------------------------------------------------

class AddFriendSheet extends StatefulWidget {
  const AddFriendSheet({super.key});

  @override
  State<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<AddFriendSheet> {
  final _controller = TextEditingController();
  String? _message;
  bool _error = false;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final social = SocialScope.read(context);
    setState(() => _busy = true);
    final result = await social.addFriend(_controller.text);
    if (!mounted) return;

    if (result == AddFriendResult.added) {
      final code = normalizeCode(_controller.text)!;
      final friend = social.friendEntries.firstWhere(
        (e) => e.profile.code == code,
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${friend.profile.avatar} ${friend.profile.nickname}님을 친구로 추가했어요!',
            ),
          ),
        );
      return;
    }

    setState(() {
      _busy = false;
      _error = true;
      _message = switch (result) {
        AddFriendResult.invalidCode => '코드는 영문·숫자 6자리예요',
        AddFriendResult.selfCode => '내 코드예요 😅 친구의 코드를 입력해 주세요',
        AddFriendResult.notFound => '이 코드를 가진 친구를 찾지 못했어요',
        AddFriendResult.alreadyFriends => '이미 친구예요!',
        AddFriendResult.added => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, 22 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '친구 추가',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            MyCodeCard(code: social.identity.code, invite: social.inviteText),
            const SizedBox(height: 18),
            const Text(
              '친구의 코드를 입력하세요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              maxLength: 7,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
                _UpperCaseFormatter(),
              ],
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 3,
                fontWeight: FontWeight.w900,
              ),
              decoration: InputDecoration(
                hintText: 'ABC-DEF',
                counterText: '',
                filled: true,
                fillColor: const Color(0xFFF6F2FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() => _message = null),
              onSubmitted: (_) => _add(),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  _message!,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _error ? const Color(0xFFD6336C) : AppColors.purple,
                  ),
                ),
              ),
            if (social.sampleCodes.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                '🧪 데모 코드로 체험해 보세요',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final code in social.sampleCodes)
                    ActionChip(
                      label: Text(
                        formatCode(code),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onPressed: () => setState(() {
                        _controller.text = formatCode(code);
                        _message = null;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _add,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '추가하기',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// "My code" card with a copy-invite button. Shared with the profile screen.
class MyCodeCard extends StatelessWidget {
  const MyCodeCard({super.key, required this.code, required this.invite});

  final String code;
  final String invite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내 친구 코드',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatCode(code),
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          PressableScale(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: invite));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('📋 초대 메시지를 복사했어요! 친구에게 보내 보세요'),
                  ),
                );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '초대 복사',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- head to head ----------------------------------------------------------

class CompareSheet extends StatelessWidget {
  const CompareSheet({super.key, required this.them});

  final PublicProfile them;

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);
    final me = social.me;
    final isFriend = social.friendEntries.any(
      (e) => !e.isMe && e.profile.code == them.code,
    );

    final rows = <_Metric>[
      _Metric('이번 주 XP', me.weeklyXp, them.weeklyXp),
      _Metric('총 XP', me.totalXp, them.totalXp),
      _Metric(
        '레벨',
        levelNumberForXp(me.totalXp),
        levelNumberForXp(them.totalXp),
      ),
      _Metric('연속 접속', me.streak, them.streak),
      _Metric('알게 된 상식', me.completed, them.completed),
      _Metric('배지', me.badgeCount, them.badgeCount),
    ];
    final wins = rows.where((r) => r.mine > r.theirs).length;
    final losses = rows.where((r) => r.mine < r.theirs).length;
    final verdict = wins > losses
        ? '이기고 있어요! 🔥'
        : wins < losses
        ? '조금만 더 힘내요! 💪'
        : '막상막하! ⚔️';

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Fighters share whatever width the score leaves, so nothing has
            // a fixed width that could overflow on a narrow screen.
            Row(
              children: [
                Expanded(
                  child: _Fighter(
                    avatar: me.avatar,
                    name: '나',
                    color: AppColors.purple,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$wins : $losses',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Expanded(
                  child: _Fighter(
                    avatar: them.avatar,
                    name: them.nickname,
                    color: AppColors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              verdict,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 18),
            for (final r in rows) _VsRow(metric: r),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isFriend
                  ? OutlinedButton(
                      onPressed: () async {
                        await social.removeFriend(them.code);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD6336C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        '친구 삭제',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    )
                  : FilledButton(
                      onPressed: () async {
                        await social.addFriend(them.code);
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        '👫 친구 추가',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.mine, this.theirs);

  final String label;
  final int mine;
  final int theirs;
}

class _Fighter extends StatelessWidget {
  const _Fighter({
    required this.avatar,
    required this.name,
    required this.color,
  });

  final String avatar;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color, width: 3),
          ),
          child: ExcludeSemantics(
            child: Text(
              avatar,
              style: const TextStyle(fontSize: 38, height: 1),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VsRow extends StatelessWidget {
  const _VsRow({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final max = metric.mine > metric.theirs ? metric.mine : metric.theirs;
    double frac(int v) => max == 0 ? 0 : v / max;
    final tie = metric.mine == metric.theirs;
    final mineWins = metric.mine > metric.theirs;

    Color barColor(bool wins, Color winColor) => tie
        ? const Color(0xFFB8B2CC)
        : (wins ? winColor : const Color(0xFFE3DEF0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Text(
            metric.label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  '${metric.mine}',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: mineWins ? AppColors.purple : AppColors.inkSoft,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: frac(metric.mine).clamp(0.02, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: barColor(mineWins, AppColors.purple),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: frac(metric.theirs).clamp(0.02, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: barColor(
                          metric.theirs > metric.mine,
                          AppColors.pink,
                        ),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 54,
                child: Text(
                  '${metric.theirs}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: metric.theirs > metric.mine
                        ? AppColors.pink
                        : AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
