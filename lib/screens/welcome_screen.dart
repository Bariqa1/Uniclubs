import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'student/student_dashboard.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  AnimationController? _animationController;
  AnimationController? _dotsController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Controller for floating dots
    _dotsController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _dotsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF578FCA),
              Color(0xFF9CAEC6),
            ],
            stops: [0.0, 0.63],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated floating dots background
              ..._buildFloatingDots(),

              // Floating decorative icons
              _buildFloatingIcon(
                icon: '🎓',
                top: 80,
                left: 30,
                delay: 0,
              ),
              _buildFloatingIcon(
                icon: '📚',
                top: 220,
                right: 40,
                delay: 200,
              ),
              _buildFloatingIcon(
                icon: '🎯',
                top: 280,
                left: 50,
                delay: 400,
              ),
              _buildFloatingIcon(
                icon: '⚽️',
                bottom: 120,
                right: 30,
                delay: 300,
              ),
              _buildFloatingIcon(
                icon: '⭐',
                bottom: 200,
                left: 40,
                delay: 500,
              ),

              // Main content
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                  const Spacer(flex: 2),
                  
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: ScaleTransition(
                      scale: _scaleAnimation!,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Logo
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 3,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.groups_rounded,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // App Name
                          const Text(
                            'UniClubs',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tagline Box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 20,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Connect, Engage, Thrive',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Your Gateway to Campus Life',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(flex: 2),
                  
                  // Start Now Button
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 100),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3674B5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black38,
                        ),
                        child: const Text(
                          'Start Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Browse as guest
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentDashboard()),
                        );
                      },
                      child: const Text(
                        'Browse as Guest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Bottom branding
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Powered by AI. Made with ❤️',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingDots() {
    if (_dotsController == null) {
      return [];
    }

    final random = math.Random(42); // Fixed seed for consistent positions
    final dots = <Widget>[];

    for (int i = 0; i < 30; i++) {
      final size = random.nextDouble() * 6 + 2; // 2-8px
      final left = random.nextDouble() * 100; // 0-100% of screen width
      final initialTop = random.nextDouble() * 100; // 0-100% of screen height
      final speed = random.nextDouble() * 0.5 + 0.3; // Different speeds
      final opacity = random.nextDouble() * 0.4 + 0.1; // 0.1-0.5 opacity

      dots.add(
        AnimatedBuilder(
          animation: _dotsController!,
          builder: (context, child) {
            final screenHeight = MediaQuery.of(context).size.height;
            final screenWidth = MediaQuery.of(context).size.width;

            // Calculate floating position
            final animationValue = (_dotsController!.value * speed) % 1.0;
            final verticalOffset = animationValue * screenHeight;
            final currentTop = (initialTop / 100 * screenHeight + verticalOffset) % screenHeight;

            return Positioned(
              left: left / 100 * screenWidth,
              top: currentTop,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      );
    }

    return dots;
  }

  Widget _buildFloatingIcon({
    required String icon,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required int delay,
  }) {
    if (_animationController == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        final adjustedDelay = delay / 1000.0;
        final progress = (_animationController!.value - adjustedDelay).clamp(0.0, 1.0);

        return Positioned(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.5 + (progress * 0.5),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}