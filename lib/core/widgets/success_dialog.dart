import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:docvault/core/constants/app_spacing.dart';

class SuccessDialog extends StatefulWidget {
  const SuccessDialog({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.autoRedirectDelay,
    this.onAutoRedirect,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final Duration? autoRedirectDelay;
  final VoidCallback? onAutoRedirect;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
    Duration? autoRedirectDelay,
    VoidCallback? onAutoRedirect,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SuccessDialog(
        icon: icon,
        title: title,
        subtitle: subtitle,
        buttonLabel: buttonLabel,
        onButtonPressed: onButtonPressed,
        autoRedirectDelay: autoRedirectDelay,
        onAutoRedirect: onAutoRedirect,
      ),
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drawProgress;
  late final Animation<double> _pulseScale;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Phase 1: draw circle + checkmark (0.0 – 0.6)
    _drawProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // Phase 2–3: pulse up then back down (0.6 – 1.0)
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0),
      ),
    );

    _controller.forward().then((_) {
      if (widget.autoRedirectDelay != null &&
          widget.onAutoRedirect != null) {
        _redirectTimer = Timer(
          widget.autoRedirectDelay!,
          widget.onAutoRedirect!,
        );
      }
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasAutoRedirect = widget.autoRedirectDelay != null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseScale.value,
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CustomPaint(
                      painter: _CheckmarkPainter(
                        progress: _drawProgress.value,
                        color: colorScheme.primary,
                        backgroundColor:
                            colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!hasAutoRedirect) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onButtonPressed,
                  child: Text(widget.buttonLabel),
                ),
              ),
            ] else
              const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle fill
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw circle stroke progressively (0.0 – 0.5 of progress)
    final circleProgress = (progress / 0.5).clamp(0.0, 1.0);
    if (circleProgress > 0) {
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      final sweepAngle = circleProgress * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -math.pi / 2,
        sweepAngle,
        false,
        circlePaint,
      );
    }

    // Draw checkmark (0.5 – 1.0 of progress)
    final checkProgress =
        ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Checkmark points relative to center
      final p1 = Offset(
        center.dx - radius * 0.28,
        center.dy + radius * 0.02,
      );
      final p2 = Offset(
        center.dx - radius * 0.05,
        center.dy + radius * 0.25,
      );
      final p3 = Offset(
        center.dx + radius * 0.32,
        center.dy - radius * 0.22,
      );

      final path = Path();

      // First segment: p1 → p2
      final seg1Progress = (checkProgress / 0.5).clamp(0.0, 1.0);
      final seg1End = Offset.lerp(p1, p2, seg1Progress)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(seg1End.dx, seg1End.dy);

      // Second segment: p2 → p3
      if (checkProgress > 0.5) {
        final seg2Progress =
            ((checkProgress - 0.5) / 0.5).clamp(0.0, 1.0);
        final seg2End = Offset.lerp(p2, p3, seg2Progress)!;
        path.lineTo(seg2End.dx, seg2End.dy);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
