import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/common/pages/onboarding_page.dart';
// AppLogo removed on splash — show text-only ProDine branding

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _contentController;
  late final AnimationController _dotsController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  bool _showSplashContent = false;
  bool _showGradient = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_contentFade);

    _introController.forward();
    // show gradient background shortly after intro starts for a smooth transition
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _showGradient = true);
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Fire-and-forget — precache in background, don't block navigation
    _precacheAssets();

    // Stage 1: show app logo immediately
    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    setState(() => _showSplashContent = true);
    _contentController.forward();

    // Stage 2: keep splash visible before route transition
    await Future.delayed(const Duration(milliseconds: 980));

    if (!mounted) return;

    // Check if onboarding has been completed
    final bool hasSeenOnboarding = await OnboardingService.isCompleted();
    final String nextRoute =
        hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding;

    context.go(nextRoute);
  }

  void _precacheAssets() {
    // Non-blocking — images load in background, ready by the time user needs them
    try {
      precacheImage(
        const AssetImage('assets/images/auth_login_header.png'),
        context,
      );
      precacheImage(const AssetImage('assets/images/app_logo.png'), context);
    } catch (_) {}
  }

  @override
  void dispose() {
    _introController.dispose();
    _contentController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;

    final bool isCompactMobile = shortestSide < 380;
    final bool isTabletOrDesktop = size.width >= 700;

    final double logoHeight = isTabletOrDesktop
        ? 150
        : isCompactMobile
            ? 92
            : 112;

    final double maxContentWidth = isTabletOrDesktop ? 520 : 360;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // animated professional gradient background
            AnimatedContainer(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _showGradient
                      ? const [Color(0xFF0F1724), Color(0xFF065F46)]
                      : [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ProDine',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _showGradient ? Colors.white : AppColors.primaryRed,
                                fontSize: logoHeight * 0.6,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'A smart cafeteria Application',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _showGradient ? Colors.white70 : const Color(0xFF344054),
                                fontSize: isTabletOrDesktop ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: !_showSplashContent
                                  ? const SizedBox(
                                      height: 1,
                                      key: ValueKey('empty'),
                                    )
                                  : SlideTransition(
                                      key: const ValueKey('content'),
                                      position: _contentSlide,
                                      child: FadeTransition(
                                        opacity: _contentFade,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            top: isCompactMobile ? 32 : 48,
                                          ),
                                          child: _ThreeDotLoader(
                                            controller: _dotsController,
                                            dotSize: isTabletOrDesktop ? 24 : 20,
                                            spacing: isTabletOrDesktop ? 16 : 14,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeDotLoader extends StatelessWidget {
  const _ThreeDotLoader({
    required this.controller,
    required this.dotSize,
    required this.spacing,
  });

  final AnimationController controller;
  final double dotSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    // Define distinct colors for each dot
    const List<Color> dotColors = [
      Color(0xFF2563EB), // Blue
      Color(0xFF059669), // Green
      Color(0xFF06B6D4), // Cyan
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double progress = (controller.value + (index * 0.22)) % 1.0;
            final double opacity = _dotOpacity(progress);
            final double scale = _dotScale(progress);
            final Color dotColor = dotColors[index];

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _dotOpacity(double value) {
    if (value < 0.5) {
      return 0.35 + (value * 1.3);
    }
    return 1.0 - ((value - 0.5) * 1.1);
  }

  double _dotScale(double value) {
    if (value < 0.5) {
      return 0.82 + (value * 0.42);
    }
    return 1.03 - ((value - 0.5) * 0.32);
  }
}
