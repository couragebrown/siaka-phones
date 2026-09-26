import 'package:flutter/material.dart';

class ManagerSplashView extends StatefulWidget {
  final VoidCallback onLoaded;
  final Duration duration;

  const ManagerSplashView({
    super.key,
    required this.onLoaded,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<ManagerSplashView> createState() => _ManagerSplashViewState();
}

class _ManagerSplashViewState extends State<ManagerSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLoaded();
      }
    });

    if (widget.duration == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLoaded();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStatusText(double value) {
    if (value < 0.25) {
      return 'Initializing Siaka Phones Manager Desktop...';
    } else if (value < 0.60) {
      return 'Verifying encrypted store session & credentials...';
    } else if (value < 0.90) {
      return 'Synchronizing inventory, orders & dispatch pipelines...';
    } else {
      return 'Ready! Launching Manager Portal...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium dark executive background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Card
              Container(
                width: 170,
                height: 170,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C7BFF).withValues(alpha: 0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/siaka_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.phone_android_rounded,
                            size: 64,
                            color: Color(0xFF1C7BFF),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'SIAKA PHONES',
                            style: TextStyle(
                              color: Color(0xFF1C7BFF),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title & Subtitle
              const Text(
                'SIAKA PHONES',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EXECUTIVE MANAGER CONSOLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Animated Progress Bar & Percentage
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) {
                  final progress = _progressAnimation.value;
                  final percentage = (progress * 100).toInt().clamp(0, 100);

                  return Column(
                    children: [
                      // Loading Bar Container
                      Container(
                        width: 320,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1C7BFF),
                                      Color(0xFF38BDF8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Status message & percentage row
                      SizedBox(
                        width: 340,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getStatusText(progress),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF38BDF8),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
