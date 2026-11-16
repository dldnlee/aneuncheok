import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Emoji avatar in a round badge.
class AvatarBubble extends StatelessWidget {
  const AvatarBubble({
    super.key,
    required this.emoji,
    this.size = 48,
    this.highlight = false,
    this.background,
  });

  final String emoji;
  final double size;

  /// Draws a purple ring - used to mark "me" in lists.
  final bool highlight;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background ?? const Color(0xFFF1ECFF),
        border: Border.all(
          color: highlight ? AppColors.purple : Colors.transparent,
          width: 3,
        ),
      ),
      child: ExcludeSemantics(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.52, height: 1)),
      ),
    );
  }
}

/// Rounded track + fill used for XP and progress bars.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.fill,
    required this.track,
    this.height = 10,
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

/// Section heading used on the ranking and profile screens.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 26, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.inkSoft,
              ),
            ),
        ],
      ),
    );
  }
}
