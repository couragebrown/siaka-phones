import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A floating customer service pill matching the reference design:
/// - Vibrant royal blue capsule background
/// - Cute white robot AI avatar on the left
/// - "Need Help?" title with "Ask our AI 😊" subtitle
/// - Golden sparkle star on the top-right
/// - Supports smooth fainted/hidden transitions when scrolling up/idle
class AiCustomerServicePill extends StatelessWidget {
  final VoidCallback onTap;
  final bool isVisible;
  final double faintedOpacity;

  const AiCustomerServicePill({
    super.key,
    required this.onTap,
    this.isVisible = false,
    this.faintedOpacity = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = isVisible ? 1.0 : faintedOpacity;
    final effectiveScale = isVisible ? 1.0 : 0.94;

    return AnimatedScale(
      scale: effectiveScale,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: effectiveOpacity,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            splashColor: Colors.white.withValues(alpha: 0.25),
            highlightColor: Colors.white.withValues(alpha: 0.15),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Capsule / Pill
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1565C0),
                        Color(0xFF0D47A1),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: isVisible
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0D47A1)
                                  .withValues(alpha: 0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : const [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // White circular avatar with AI bot face
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          size: const Size(36, 36),
                          painter: _AiBotAvatarPainter(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Text details
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 1.5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ask our AI',
                                style: TextStyle(
                                  color: Color(0xFFD0E2FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                  height: 1.15,
                                ),
                              ),
                              SizedBox(width: 3),
                              Text(
                                '😊',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Golden Sparkle Star at Top-Right
                Positioned(
                  top: -5,
                  right: 8,
                  child: CustomPaint(
                    size: const Size(16, 16),
                    painter: _SparkleStarPainter(),
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

/// Custom painter to draw the cute 3D-styled AI Robot head matching the reference image
class _AiBotAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Head base position
    final headRect = Rect.fromCenter(
      center: Offset(cx, cy + 0.5),
      width: 23,
      height: 19,
    );

    // Side headphones / ears
    final earPaint = Paint()..color = const Color(0xFFE2E8F0);
    // Left ear
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 10.5, cy + 0.5),
          width: 3.5,
          height: 8.5,
        ),
        const Radius.circular(2),
      ),
      earPaint,
    );
    // Right ear
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 10.5, cy + 0.5),
          width: 3.5,
          height: 8.5,
        ),
        const Radius.circular(2),
      ),
      earPaint,
    );

    // Robot White Head
    final headPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE2E8F0),
        ],
      ).createShader(headRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, const Radius.circular(9)),
      headPaint,
    );

    // Dark Visor / Screen Face
    final visorRect = Rect.fromCenter(
      center: Offset(cx, cy + 0.8),
      width: 15.5,
      height: 11,
    );
    final visorPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(visorRect, const Radius.circular(5.5)),
      visorPaint,
    );

    // Glowing Cyan Eyes
    final eyePaint = Paint()..color = const Color(0xFF00E5FF);
    final pupilPaint = Paint()..color = const Color(0xFF0F172A);

    final leftEye = Offset(cx - 3.6, cy + 0.2);
    final rightEye = Offset(cx + 3.6, cy + 0.2);

    canvas.drawCircle(leftEye, 1.8, eyePaint);
    canvas.drawCircle(leftEye, 0.7, pupilPaint);

    canvas.drawCircle(rightEye, 1.8, eyePaint);
    canvas.drawCircle(rightEye, 0.7, pupilPaint);

    // Cute Cyan Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 1.8, cy + 3.8),
      Offset(cx + 1.8, cy + 3.8),
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter to draw the sparkling 4-point gold star on the top-right of the pill
class _SparkleStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final innerR = r * 0.28;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final nextAngle = angle + (math.pi / 4);

      final px = cx + r * math.cos(angle - math.pi / 2);
      final py = cy + r * math.sin(angle - math.pi / 2);

      final ipx = cx + innerR * math.cos(nextAngle - math.pi / 2);
      final ipy = cy + innerR * math.sin(nextAngle - math.pi / 2);

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
      path.lineTo(ipx, ipy);
    }
    path.close();

    // Drop shadow for sparkle
    final shadowPaint = Paint()
      ..color = const Color(0xFFFFA000).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, shadowPaint);

    // Golden yellow star fill
    final starPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
