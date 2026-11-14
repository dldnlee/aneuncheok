import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../social/social_store.dart';
import '../theme/app_theme.dart';
import '../widgets/effects.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'ranking_screen.dart';

/// Home / ranking / profile tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const rankingTab = 1;

  int _index = 0;

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    // Fresh numbers whenever the ranking tab is opened.
    if (index == rankingTab) SocialScope.read(context).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final social = SocialScope.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenRanking: () => _select(rankingTab)),
          const RankingScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        profileEmoji: social.identity.avatar,
        onSelect: _select,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.profileEmoji,
    required this.onSelect,
  });

  final int index;
  final String profileEmoji;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [('🏠', '홈'), ('🏆', '랭킹'), (profileEmoji, '나')];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFE7DD), width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    emoji: items[i].$1,
                    label: items[i].$2,
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.92,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1ECFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.18 : 1,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: ExcludeSemantics(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 24, height: 1.1),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? AppColors.purple : AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
