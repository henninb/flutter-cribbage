import 'package:flutter/material.dart';

/// Score Animation Widget
/// Shows a "+X" animation that pops up and fades out
/// Used for both pegging and hand counting scores
class ScoreAnimationWidget extends StatefulWidget {
  final int points;
  final bool isPlayer;
  final VoidCallback onAnimationComplete;
  final Color? color;

  const ScoreAnimationWidget({
    super.key,
    required this.points,
    required this.isPlayer,
    required this.onAnimationComplete,
    this.color,
  });

  @override
  State<ScoreAnimationWidget> createState() => _ScoreAnimationWidgetState();
}

class _ScoreAnimationWidgetState extends State<ScoreAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Create animation controller (total duration: 2.8 seconds)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    // Scale animation: pop from 0 to 1.2 with bounce
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.2),
        weight: 60,
      ),
    ]).animate(_controller);

    // Fade animation: stay visible for a bit, then fade out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 70,
      ),
    ]).animate(_controller);

    // Start animation and call completion callback when done
    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use provided color or default based on player/opponent
    final animationColor = widget.color ??
        (widget.isPlayer
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Text(
              '+${widget.points}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: animationColor,
                  ),
            ),
          ),
        );
      },
    );
  }
}
