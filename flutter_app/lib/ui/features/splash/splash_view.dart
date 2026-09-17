import 'package:flutter/material.dart';

/// The first page that appears after the app is launched.
/// Displays the official Siaka Phones logo with appropriate sizing
/// and an animated loading bar state before entering the app.
class SplashView extends StatefulWidget {
  final VoidCallback onLoaded;
  final Duration duration;

  const SplashView({
    super.key,
    required this.onLoaded,
    this.duration = const Duration(milliseconds: 2200),
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.95, curve: Curves.easeInOutCubic),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerCompletion();
      }
    });
  }

  bool _hasTriggeredOnLoaded = false;

  void _triggerCompletion() {
    if (_hasTriggeredOnLoaded) return;
    _hasTriggeredOnLoaded = true;
    if (mounted) {
      widget.onLoaded();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStatusText(double progress) {
    if (progress < 0.35) {
      return 'Initializing flagship store...';
    } else if (progress < 0.75) {
      return 'Loading devices & accessories...';
    } else if (progress < 0.98) {
      return 'Preparing your personalized experience...';
    }
    return 'Welcome to Siaka Phones!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _triggerCompletion,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _progressAnimation.value;
              final percentage = (progress * 100).toInt();

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Official Logo with Fade & Scale Animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 250,
                          height: 250,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/siaka_logo.png',
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback in case asset is loading
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.phone_android_rounded,
                                    size: 80,
                                    color: Color(0xFF1C7BFF),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'SIAKA PHONES',
                                    style: TextStyle(
                                      color: Color(0xFF1C7BFF),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Modern Loading Bar State
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Progress Track & Animated Fill
                          Container(
                            width: 220,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                                width: 0.8,
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
                                          Color(0xFF3B82F6),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1C7BFF)
                                              .withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Status text & Percentage Counter
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getStatusText(progress),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$percentage%',
                                style: const TextStyle(
                                  color: Color(0xFF1C7BFF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
