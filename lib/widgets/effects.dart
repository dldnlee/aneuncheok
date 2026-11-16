import 'dart:math' as math;

import 'package:flutter/material.dart';

/// True when the user asked the OS to reduce motion. Every looping or
/// decorative animation in the app checks this.
bool reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Fade + slide-up route used to open the vertical feed.
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Squishes slightly while pressed - makes every tap feel physical.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.94,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      onTap: widget.onTap,
      child: MergeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? widget.pressedScale : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Fades and slides its child up once, [delay] after the build starts.
/// Implemented with an Interval so no timers are left pending.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 24,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;

  static const _run = Duration(milliseconds: 450);

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final total = _run + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offsetY),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Pops in with a springy overshoot.
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, t, child) =>
          Transform.scale(scale: t.clamp(0.0, 1.4), child: child),
      child: child,
    );
  }
}

/// Loops a gentle motion (bob / wiggle / pulse) on its child.
/// Does nothing when the user prefers reduced motion.
class Loop extends StatefulWidget {
  const Loop({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 1800),
  });

  /// Called with a value that eases 0 -> 1 -> 0 forever.
  final Widget Function(BuildContext context, double t) builder;
  final Duration duration;

  @override
  State<Loop> createState() => _LoopState();
}

class _LoopState extends State<Loop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) =>
          widget.builder(context, Curves.easeInOut.transform(_c.value)),
    );
  }
}

/// Soft, translucent circles used as background decoration.
class Bubble extends StatelessWidget {
  const Bubble({super.key, required this.size, this.opacity = 0.12});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
    required this.circle,
  });

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;
  final bool circle;
}

/// Full-size overlay that shoots confetti when [ConfettiLayerState.burst]
/// is called. Ignores pointer events.
class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key});

  @override
  State<ConfettiLayer> createState() => ConfettiLayerState();
}

class ConfettiLayerState extends State<ConfettiLayer>
    with SingleTickerProviderStateMixin {
  static const _seconds = 1.5;
  static const _palette = [
    Color(0xFFFFD43B),
    Color(0xFFFF4D8D),
    Color(0xFF4DD0E1),
    Color(0xFFFFFFFF),
    Color(0xFF9B6BFF),
    Color(0xFF69DB7C),
    Color(0xFFFF8A1F),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  final _rnd = math.Random();
  List<_Particle> _particles = const [];
  Offset _origin = const Offset(0.5, 0.75);

  /// [origin] is in 0..1 of the layer size. [strength] scales particle count.
  void burst({Offset origin = const Offset(0.5, 0.75), double strength = 1}) {
    if (reduceMotion(context)) return;
    _origin = origin;
    _particles = List.generate((70 * strength).round(), (_) {
      return _Particle(
        angle: -math.pi * (0.1 + 0.8 * _rnd.nextDouble()),
        speed: 380 + 620 * _rnd.nextDouble(),
        size: 6 + 7 * _rnd.nextDouble(),
        spin: (_rnd.nextDouble() - 0.5) * 18,
        color: _palette[_rnd.nextInt(_palette.length)],
        circle: _rnd.nextBool(),
      );
    });
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _origin, _c.value),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.origin, this.progress);

  final List<_Particle> particles;
  final Offset origin;
  final double progress;

  static const _gravity = 1500.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0 || progress == 1 || particles.isEmpty) return;
    final t = progress * ConfettiLayerState._seconds;
    final fade = progress < 0.7 ? 1.0 : (1 - progress) / 0.3;
    final o = Offset(size.width * origin.dx, size.height * origin.dy);
    final paint = Paint();
    for (final p in particles) {
      final pos =
          o +
          Offset(
            math.cos(p.angle) * p.speed * t,
            math.sin(p.angle) * p.speed * t + 0.5 * _gravity * t * t,
          );
      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
