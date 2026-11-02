import 'package:flutter/material.dart';

class LiveMiniMapPainter extends CustomPainter {
  final bool isLocated;

  const LiveMiniMapPainter({required this.isLocated});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFEFF4F8);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle green park patches
    final parkPaint = Paint()..color = const Color(0xFFD9F2E1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.12, size.width * 0.24, size.height * 0.42),
        const Radius.circular(6),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72, size.height * 0.18, size.width * 0.22, size.height * 0.36),
        const Radius.circular(6),
      ),
      parkPaint,
    );

    // Subtle water curve on bottom-right
    final waterPaint = Paint()
      ..color = const Color(0xFFC7E2FE)
      ..style = PaintingStyle.fill;
    final waterPath = Path()
      ..moveTo(size.width * 0.65, size.height)
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.62,
        size.width,
        size.height * 0.52,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Secondary neighborhood streets
    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;
    for (final frac in [0.22, 0.48, 0.74]) {
      canvas.drawLine(
        Offset(size.width * frac, 0),
        Offset(size.width * (frac + 0.06), size.height),
        minorRoadPaint,
      );
    }
    canvas.drawLine(
      Offset(0, size.height * 0.34),
      Offset(size.width, size.height * 0.28),
      minorRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width, size.height * 0.74),
      minorRoadPaint,
    );

    // Main arterial road
    final mainRoadCasing = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke;
    final mainRoadFill = Paint()
      ..color = const Color(0xFFFEF9C3)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;
    final mainRoadPath = Path()
      ..moveTo(0, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.42,
        size.width,
        size.height * 0.46,
      );
    canvas.drawPath(mainRoadPath, mainRoadCasing);
    canvas.drawPath(mainRoadPath, mainRoadFill);

    // Center GPS radar halo & pin
    final pinCenter = Offset(size.width * 0.5, size.height * 0.45);
    final accentColor = isLocated ? const Color(0xFF16A34A) : const Color(0xFF1C7BFF);

    canvas.drawCircle(
      pinCenter,
      19,
      Paint()..color = accentColor.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      pinCenter,
      19,
      Paint()
        ..color = accentColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // White ring + live dot
    canvas.drawCircle(pinCenter, 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(pinCenter, 6.0, Paint()..color = accentColor);
  }

  @override
  bool shouldRepaint(covariant LiveMiniMapPainter oldDelegate) {
    return oldDelegate.isLocated != isLocated;
  }
}

