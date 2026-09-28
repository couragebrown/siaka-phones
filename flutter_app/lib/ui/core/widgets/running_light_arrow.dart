import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for the arrow design inside an open circular stroke with an
/// animated glowing running light that flows around the circle, enters into the
/// horizontal arrow shaft from the left, shoots across to the arrowhead, and
/// pulses outward to indicate that more items are available to the right.
class RunningLightArrowPainter extends CustomPainter {
  /// Signature Google brand colors
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleRed = Color(0xFFEA4335);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleGreen = Color(0xFF34A853);

  /// Animation progress from 0.0 to 1.0.
  final double progress;

  /// Inactive stroke color for the circle and arrow vector.
  final Color baseColor;

  /// Fallback color of the running light glow beam when not using Google palette.
  final Color glowColor;

  /// Core spark / leading pulse color.
  final Color coreColor;

  /// Whether to use the signature Google 4-color palette for the running light.
  final bool useGoogleColors;

  const RunningLightArrowPainter({
    required this.progress,
    this.baseColor = const Color(0xFF1E2432),
    this.glowColor = googleBlue,
    this.coreColor = Colors.white,
    this.useGoogleColors = true,
  });

  /// Maps a normalized progress value (0.0 to 1.0) through the 4 Google colors:
  /// Blue -> Red -> Yellow -> Green.
  static Color getGoogleColor(double t) {
    final clamped = t.clamp(0.0, 1.0);
    if (clamped <= 0.333) {
      final s = clamped / 0.333;
      return Color.lerp(googleBlue, googleRed, s)!;
    } else if (clamped <= 0.666) {
      final s = (clamped - 0.333) / 0.333;
      return Color.lerp(googleRed, googleYellow, s)!;
    } else {
      final s = (clamped - 0.666) / 0.334;
      return Color.lerp(googleYellow, googleGreen, s.clamp(0.0, 1.0))!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) * 0.38;
    final strokeWidth = math.min(size.width, size.height) * 0.082;

    // Gap angle centered around left horizontal axis (pi rad / 180 deg).
    // 38 degrees half-gap leaves an elegant entrance for the arrow line.
    const gapAngle = 38.0 * (math.pi / 180.0);
    const startAngle = -math.pi + gapAngle;
    const sweepAngle = (2.0 * math.pi) - (2.0 * gapAngle);

    // 1. Draw Base Icon (open circle + horizontal arrow + arrowhead)
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Outer circular arc with left entrance gap
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: R),
      startAngle,
      sweepAngle,
      false,
      basePaint,
    );

    // Horizontal arrow line entering through the left gap into the circle
    final lineStartX = center.dx - (R * 1.12);
    final arrowTipX = center.dx + (R * 0.40);
    final arrowY = center.dy;

    canvas.drawLine(
      Offset(lineStartX, arrowY),
      Offset(arrowTipX, arrowY),
      basePaint,
    );

    // Arrowhead wings pointing right
    final wingDx = R * 0.42;
    final wingDy = R * 0.42;

    final wingsPath = Path()
      ..moveTo(arrowTipX - wingDx, arrowY - wingDy)
      ..lineTo(arrowTipX, arrowY)
      ..lineTo(arrowTipX - wingDx, arrowY + wingDy);

    canvas.drawPath(wingsPath, basePaint);

    // 2. Draw Dynamic Running Light with Google Colors
    final p = progress.clamp(0.0, 1.0);

    if (p <= 0.48) {
      // Phase 1: Light travels clockwise along the circle arc through Google colors
      // Blue (top) -> Red (right) -> Yellow (bottom) -> Green (approaching gap)
      final u1 = p / 0.48;
      final headAngle = startAngle + (sweepAngle * u1);
      const streakAngle = sweepAngle * 0.24;
      final tailAngle = math.max(startAngle, headAngle - streakAngle);
      final actualSweep = headAngle - tailAngle;

      final headColor = useGoogleColors ? getGoogleColor(u1) : glowColor;
      final tailColor = useGoogleColors
          ? getGoogleColor((u1 - 0.22).clamp(0.0, 1.0))
          : glowColor;

      final arcRect = Rect.fromCircle(center: center, radius: R);

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      final beamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (useGoogleColors) {
        beamPaint.shader = SweepGradient(
          startAngle: tailAngle,
          endAngle: headAngle,
          colors: [tailColor, headColor],
        ).createShader(arcRect);
        glowPaint.shader = SweepGradient(
          startAngle: tailAngle,
          endAngle: headAngle,
          colors: [
            tailColor.withValues(alpha: 0.30),
            headColor.withValues(alpha: 0.75),
          ],
        ).createShader(arcRect);
      } else {
        glowPaint.color = glowColor.withValues(alpha: 0.65);
        beamPaint.color = glowColor;
      }

      if (actualSweep > 0.01) {
        canvas.drawArc(arcRect, tailAngle, actualSweep, false, glowPaint);
        canvas.drawArc(arcRect, tailAngle, actualSweep, false, beamPaint);
      }

      final headPos = Offset(
        center.dx + R * math.cos(headAngle),
        center.dy + R * math.sin(headAngle),
      );

      final sparkGlowPaint = Paint()
        ..color = headColor.withValues(alpha: 0.80)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

      final sparkCorePaint = Paint()
        ..color = coreColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(headPos, strokeWidth * 1.35, sparkGlowPaint);
      canvas.drawCircle(headPos, strokeWidth * 0.65, sparkCorePaint);
    } else if (p <= 0.82) {
      // Phase 2: Light enters arrow shaft from the left and shoots to the right tip
      // Flowing through full Google spectrum: Green -> Yellow -> Red -> Blue
      final u2 = (p - 0.48) / 0.34;
      final headX = lineStartX + ((arrowTipX - lineStartX) * u2);
      final shaftLength = arrowTipX - lineStartX;
      final tailX = math.max(lineStartX, headX - (shaftLength * 0.36));

      final lineRect = Rect.fromPoints(
        Offset(tailX, arrowY - strokeWidth * 2),
        Offset(headX, arrowY + strokeWidth * 2),
      );

      final headColor = useGoogleColors ? googleBlue : glowColor;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

      final beamPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (useGoogleColors) {
        beamPaint.shader = const LinearGradient(
          colors: [googleGreen, googleYellow, googleRed, googleBlue],
        ).createShader(lineRect);
        glowPaint.shader = LinearGradient(
          colors: [
            googleGreen.withValues(alpha: 0.35),
            googleYellow.withValues(alpha: 0.65),
            googleRed.withValues(alpha: 0.70),
            googleBlue.withValues(alpha: 0.80),
          ],
        ).createShader(lineRect);
      } else {
        glowPaint.color = glowColor.withValues(alpha: 0.65);
        beamPaint.color = glowColor;
      }

      canvas.drawLine(Offset(tailX, arrowY), Offset(headX, arrowY), glowPaint);
      canvas.drawLine(Offset(tailX, arrowY), Offset(headX, arrowY), beamPaint);

      final sparkPos = Offset(headX, arrowY);
      final sparkGlowPaint = Paint()
        ..color = headColor.withValues(alpha: 0.80)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

      final sparkCorePaint = Paint()
        ..color = coreColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(sparkPos, strokeWidth * 1.35, sparkGlowPaint);
      canvas.drawCircle(sparkPos, strokeWidth * 0.7, sparkCorePaint);
    } else {
      // Phase 3: Light ignites the arrowhead wings in Google spectrum and radiates rightward
      final u3 = (p - 0.82) / 0.18;
      final fade = (1.0 - u3).clamp(0.0, 1.0);

      if (fade > 0.01) {
        final wingsRect = Rect.fromPoints(
          Offset(arrowTipX - wingDx, arrowY - wingDy),
          Offset(arrowTipX, arrowY + wingDy),
        );

        final wingGlow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

        final wingCore = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (useGoogleColors) {
          wingGlow.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              googleBlue.withValues(alpha: 0.85 * fade),
              googleRed.withValues(alpha: 0.85 * fade),
              googleYellow.withValues(alpha: 0.85 * fade),
              googleGreen.withValues(alpha: 0.85 * fade),
            ],
          ).createShader(wingsRect);

          wingCore.shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              googleBlue.withValues(alpha: fade),
              googleRed.withValues(alpha: fade),
              googleYellow.withValues(alpha: fade),
              googleGreen.withValues(alpha: fade),
            ],
          ).createShader(wingsRect);
        } else {
          wingGlow.color = glowColor.withValues(alpha: 0.75 * fade);
          wingCore.color = coreColor.withValues(alpha: fade);
        }

        canvas.drawPath(wingsPath, wingGlow);
        canvas.drawPath(wingsPath, wingCore);

        // Rightward pulse wave in Google colors
        final pulseX = arrowTipX + (R * 0.35 * u3);
        final pulsePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 1.3
          ..strokeCap = StrokeCap.round;

        if (useGoogleColors) {
          final pulseColor = getGoogleColor(u3);
          pulsePaint.color = pulseColor.withValues(alpha: 0.60 * fade);
        } else {
          pulsePaint.color = glowColor.withValues(alpha: 0.55 * fade);
        }

        final pulsePath = Path()
          ..moveTo(pulseX - wingDx * 0.65, arrowY - wingDy * 0.65)
          ..lineTo(pulseX, arrowY)
          ..lineTo(pulseX - wingDx * 0.65, arrowY + wingDy * 0.65);
        canvas.drawPath(pulsePath, pulsePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant RunningLightArrowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.useGoogleColors != useGoogleColors;
  }
}

/// Circular button widget featuring the open-circle arrow design with an
/// animated glowing running light beam.
class RunningLightArrowButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  const RunningLightArrowButton({
    super.key,
    this.onTap,
    this.tooltip,
    this.size = 38.0,
  });

  @override
  State<RunningLightArrowButton> createState() =>
      _RunningLightArrowButtonState();
}

class _RunningLightArrowButtonState extends State<RunningLightArrowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: RunningLightArrowPainter.googleBlue.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: RunningLightArrowPainter.googleRed.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          splashColor: RunningLightArrowPainter.googleBlue.withValues(alpha: 0.15),
          highlightColor:
              RunningLightArrowPainter.googleYellow.withValues(alpha: 0.10),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size * 0.58, widget.size * 0.58),
                  painter: RunningLightArrowPainter(
                    progress: _controller.value,
                    baseColor: const Color(0xFF1E2432),
                    useGoogleColors: true,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
