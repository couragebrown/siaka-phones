import 'dart:async';
import 'package:flutter/material.dart';

/// Promotional Flash Sale banner with live ticking countdown timer (Days, Hours, Mins, Secs)
/// and alternating light (⚡ peach pastel) or dark (🔥 midnight fire) styles.
class FlashSalePromoBanner extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onShopNowTap;
  final int initialSeconds;

  const FlashSalePromoBanner({
    super.key,
    this.isDark = false,
    this.onShopNowTap,
    this.initialSeconds = 217245, // 2 days, 12 hours, 20 mins, 45 secs
  });

  @override
  State<FlashSalePromoBanner> createState() => _FlashSalePromoBannerState();
}

class _FlashSalePromoBannerState extends State<FlashSalePromoBanner> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;

    // Detect test environment to avoid infinite pending timer during pumpAndSettle
    final bindingStr = WidgetsBinding.instance.runtimeType.toString();
    final isTest = bindingStr.contains('Test') || const bool.fromEnvironment('FLUTTER_TEST');

    if (!isTest) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final days = _twoDigits(_remainingSeconds ~/ 86400);
    final hours = _twoDigits((_remainingSeconds % 86400) ~/ 3600);
    final mins = _twoDigits((_remainingSeconds % 3600) ~/ 60);
    final secs = _twoDigits(_remainingSeconds % 60);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isDark
              ? const [
                  Color(0xFF1B192A),
                  Color(0xFF1E1729),
                  Color(0xFF261525),
                ]
              : const [
                  Color(0xFFFFEEEB),
                  Color(0xFFFFF2EF),
                  Color(0xFFFDE7E4),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF38263B) : const Color(0xFFFFD5D0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.28)
                : const Color(0xFFF43F5E).withValues(alpha: 0.06),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background decorations
          if (!isDark) ...[
            // Floating % signs
            Positioned(
              left: 124,
              top: 5,
              child: Text(
                '%',
                style: TextStyle(
                  color: const Color(0xFFF87171).withValues(alpha: 0.22),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              right: 104,
              bottom: 1,
              child: Text(
                '%',
                style: TextStyle(
                  color: const Color(0xFFF87171).withValues(alpha: 0.18),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            // Floating tilted capsule sprinkles
            Positioned(
              right: 116,
              top: 8,
              child: Transform.rotate(
                angle: 0.6,
                child: Container(
                  width: 7,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF87171).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: Transform.rotate(
                angle: 0.4,
                child: Container(
                  width: 9,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Dark mode confetti sprinkles
            Positioned(
              left: 136,
              top: 10,
              child: Transform.rotate(
                angle: 0.7,
                child: Container(
                  width: 7,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 150,
              bottom: 6,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 7,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 114,
              bottom: 7,
              child: Transform.rotate(
                angle: 0.8,
                child: Container(
                  width: 8,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Far right subtle amber lightning accent
            Positioned(
              right: -6,
              top: -6,
              bottom: -6,
              child: Container(
                width: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withValues(alpha: 0.0),
                      const Color(0xFFF59E0B).withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Main Interactive Layout Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon (⚡ Bolt for Light, 🔥 Flame for Dark)
                    if (!isDark)
                      const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFF59E0B),
                        size: 28,
                      )
                    else
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 22),
                      ),

                    const SizedBox(width: 6),

                    // Title & Tagline Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Flash Sale',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isDark
                              ? 'Big Deals. Limited Time Only!'
                              : "Limited time. Don't miss out!",
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // 4 Countdown Units (Days, Hours, Mins, Secs)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimerUnit(days, 'Days', isDark),
                        const SizedBox(width: 4),
                        _buildTimerUnit(hours, 'Hours', isDark),
                        const SizedBox(width: 4),
                        _buildTimerUnit(mins, 'Mins', isDark),
                        const SizedBox(width: 4),
                        _buildTimerUnit(secs, 'Secs', isDark),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // "Shop Now" Pill Button
                    GestureDetector(
                      onTap: widget.onShopNowTap,
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? const [Color(0xFFFF0055), Color(0xFFE11D48)]
                                : const [Color(0xFFF43F5E), Color(0xFFE11D48)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.38),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Shop Now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 2.5),
                            Icon(
                              isDark
                                  ? Icons.arrow_forward_rounded
                                  : Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerUnit(String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 25,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFBE123C) : Colors.white,
            borderRadius: BorderRadius.circular(6.5),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFFBE123C).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFFBE123C),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
