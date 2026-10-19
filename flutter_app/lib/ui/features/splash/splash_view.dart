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
    this.duration = const Duration(milliseconds: 5000),
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
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
              // Ensure the loading bar is always visible at the beginning of the bar (minimum 6% indicator so the starting edge of the bar is never empty)
              final barFillFactor = (0.06 + (progress * 0.94)).clamp(0.06, 1.0);

              return Stack(
                children: [
                  // Centered Logo, Progress Bar, and Status
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Official Siaka Phones Logo (matched to native Android splash size for seamless transition)
                          Container(
                            width: 175,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/siaka_logo.png',
                              width: 175,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.phone_android_rounded,
                                      size: 70,
                                      color: Color(0xFF1C7BFF),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'SIAKA PHONES',
                                      style: TextStyle(
                                        color: Color(0xFF1C7BFF),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Sleek, refined Loading Bar Under Logo (compact 160x4 dimensions)
                          Column(
                            children: [
                              // Progress Track & Animated Fill
                              Container(
                                width: 160,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 0.8,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(100),
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      // Track background ensuring full bar is visible from frame 0
                                      Container(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                      // Animated fill anchored from the beginning (left)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: barFillFactor,
                                          heightFactor: 1.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF1C7BFF),
                                                  Color(0xFF3B82F6),
                                                  Color(0xFF60A5FA),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF1C7BFF)
                                                      .withValues(alpha: 0.35),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Status text & Percentage Counter
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getStatusText(progress),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      color: Color(0xFF1C7BFF),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom copyright protection notice
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: Color(0xFF1C7BFF),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '© ${DateTime.now().year} Siaka Phones Ltd.',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'All rights reserved. Protected by copyright law.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
