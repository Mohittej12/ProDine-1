import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track onboarding completion state
class OnboardingService {
  static const String _key = 'onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _activePage = 0;
  bool _isNavigating = false;

  // Live interpolated colors used for smoother transitions while swiping
  late Color _currentCtaColor;
  late Color _currentAccentColor;
  late List<Color> _currentBackground;

  late final AnimationController _slideAnimationController;
  late final Animation<double> _slideAnimation;

  static final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'Order in a flash',
      subtitle:
          'Discover cafeteria favorites, order ahead, and skip the queue with smart one-tap checkout. Designed for fast campus dining and reduced wait times.',
      accent: 'Fresh picks every day',
      background: const [Color(0xFFF3F7FB), Color(0xFFEFF6FB)],
      icon: Icons.local_mall_outlined,
      accentColor: Color(0xFF1E3A8A),
      ctaColor: Color(0xFF2563EB),
    ),
    _OnboardingSlide(
      title: 'Track every meal',
      subtitle:
          'See your order status in real time, manage favorites, and get meal reminders instantly. Clear timing and kitchen updates help staff and students.',
      accent: 'Live tray updates',
      background: const [Color(0xFFF7FBF9), Color(0xFFF0F9F4)],
      icon: Icons.track_changes_outlined,
      accentColor: Color(0xFF059669),
      ctaColor: Color(0xFF06B6D4),
    ),
    _OnboardingSlide(
      title: 'Rewards that matter',
      subtitle:
          'Earn loyalty gifts, speed up checkout, and experience cafeteria service made effortless. Reward programs that scale for campuses of any size.',
      accent: 'Priority meal lanes',
      background: const [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
      icon: Icons.stars_outlined,
      accentColor: Color(0xFF0F1724),
      ctaColor: Color(0xFF0EA5A4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOut),
    );

    _slideAnimationController.forward();

    // initialize live colors to first slide
    final first = _slides.first;
    _currentCtaColor = first.ctaColor;
    _currentAccentColor = first.accentColor;
    _currentBackground = first.background;

    // listen to page scrolls to interpolate colors between slides
    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    final page = _pageController.hasClients ? (_pageController.page ?? _activePage.toDouble()) : _activePage.toDouble();
    final base = page.floor();
    final t = (page - base).clamp(0.0, 1.0);

    if (base < 0 || base >= _slides.length) return;

    if (base == _slides.length - 1) {
      final s = _slides.last;
      if (mounted) setState(() {
        _currentCtaColor = s.ctaColor;
        _currentAccentColor = s.accentColor;
        _currentBackground = s.background;
      });
      return;
    }

    final a = _slides[base];
    final b = _slides[base + 1];

    final lerp0 = Color.lerp(a.background[0], b.background[0], t)!;
    final lerp1 = Color.lerp(a.background[1], b.background[1], t)!;
    final cta = Color.lerp(a.ctaColor, b.ctaColor, t)!;
    final accent = Color.lerp(a.accentColor, b.accentColor, t)!;

    if (mounted) setState(() {
      _currentBackground = [lerp0, lerp1];
      _currentCtaColor = cta;
      _currentAccentColor = accent;
    });
  }

  Future<void> _goNext() async {
    if (_isNavigating) return;

    if (_activePage < _slides.length - 1) {
      _isNavigating = true;
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
      );
      _isNavigating = false;
      return;
    }

    // Mark onboarding as completed
    await OnboardingService.markCompleted();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _skip() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await OnboardingService.markCompleted();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 640;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
            child: Stack(
          children: [
            // animated background gradient that follows swipe position
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _currentBackground,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            _buildAnimatedBackgroundBubbles(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  _buildTopBar(theme),
                  const SizedBox(height: 18),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _slides.length,
                      onPageChanged: (index) {
                        setState(() {
                          _activePage = index;
                        });
                        _slideAnimationController.reset();
                        _slideAnimationController.forward();
                      },
                      itemBuilder: (context, index) {
                        return _OnboardingSlideCard(
                          slide: _slides[index],
                          isWide: isWide,
                          animation: _slideAnimation,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildIndicatorRow(),
                  const SizedBox(height: 24),
                  _buildActionButtons(theme),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return FadeTransition(
      opacity: _slideAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ProDine',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Food ordering reimagined for your campus.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: _skip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackgroundBubbles() {
    // use interpolated colors for a more cohesive animated effect
    final accent = _currentAccentColor;
    final cta = _currentCtaColor;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          top: -50,
          left: -34,
          child: _BlurBubble(
            size: 180,
            color: accent.withOpacity(0.16),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          top: 120,
          right: -60,
          child: _BlurBubble(
            size: 220,
            color: cta.withOpacity(0.12),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          bottom: -34,
          left: 20,
          child: _BlurBubble(
            size: 140,
            color: accent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorRow() {
    return ScaleTransition(
      scale: _slideAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _slides.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            width: _activePage == index ? 28 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _activePage == index
                  ? _currentAccentColor
                  : AppColors.textSecondary.withOpacity(0.24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return ScaleTransition(
      scale: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimatedPrimaryButton(
            label: _activePage == _slides.length - 1 ? 'Get started' : 'Next',
            backgroundColor: _currentCtaColor,
            onPressed: _goNext,
            isLoading: _isNavigating,
          ),
          const SizedBox(height: 12),
          _AnimatedSecondaryButton(
            label: 'Sign in instead',
            accentColor: _currentAccentColor,
            onPressed: _skip,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String accent;
  final List<Color> background;
  final IconData icon;
  final Color accentColor;
  final Color ctaColor;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.background,
    required this.icon,
    required this.accentColor,
    required this.ctaColor,
  });
}

class _OnboardingSlideCard extends StatelessWidget {
  final _OnboardingSlide slide;
  final bool isWide;
  final Animation<double> animation;

  const _OnboardingSlideCard({
    required this.slide,
    required this.isWide,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: animation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            width: isWide ? 640 : double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.background,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withOpacity(0.12),
                  blurRadius: 42,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.4, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                  ),
                  child: Row(
                    children: [
                      _FeatureCircle(
                        icon: slide.icon,
                        accentColor: slide.accentColor,
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          slide.accent,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: slide.accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.3, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
                    ),
                  ),
                  child: Text(
                    slide.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.2, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
                    ),
                  ),
                  child: Text(
                    slide.subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
                  ),
                  child: Row(
                    children: [
                      _BenefitTag(
                        label: 'Quick ordering',
                        accentColor: slide.accentColor,
                      ),
                      const SizedBox(width: 10),
                      _BenefitTag(
                        label: 'Smart suggestions',
                        accentColor: slide.accentColor,
                      ),
                    ],
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

class _FeatureCircle extends StatelessWidget {
  final IconData icon;
  final Color accentColor;

  const _FeatureCircle({
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'feature_icon_${icon.codePoint}',
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 32,
          color: accentColor,
        ),
      ),
    );
  }
}

class _BenefitTag extends StatefulWidget {
  final String label;
  final Color accentColor;

  const _BenefitTag({
    required this.label,
    required this.accentColor,
  });

  @override
  State<_BenefitTag> createState() => _BenefitTagState();
}

class _BenefitTagState extends State<_BenefitTag>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onEnter() {
    _hoverController.forward();
  }

  void _onExit() {
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: ScaleTransition(
        scale: _hoverAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _BlurBubble extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurBubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 72,
            spreadRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _AnimatedPrimaryButton extends StatefulWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const _AnimatedPrimaryButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    required this.isLoading,
  });

  @override
  State<_AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<_AnimatedPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _pressAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handlePressed() {
    _pressController.forward().then((_) {
      _pressController.reverse();
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: widget.backgroundColor.withOpacity(0.36),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.isLoading ? null : _handlePressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            disabledBackgroundColor: widget.backgroundColor.withOpacity(0.6),
          ),
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                )
              : Text(
                  widget.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
        ),
      ),
    );
  }
}

class _AnimatedSecondaryButton extends StatefulWidget {
  final String label;
  final Color accentColor;
  final VoidCallback onPressed;

  const _AnimatedSecondaryButton({
    required this.label,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedSecondaryButton> createState() =>
      _AnimatedSecondaryButtonState();
}

class _AnimatedSecondaryButtonState extends State<_AnimatedSecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<Color?> _colorAnimation;
  late final Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.accentColor.withOpacity(0.08),
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));

    _shadowAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _hoverController.forward(),
      onExit: (_) => _hoverController.reverse(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.12),
                  blurRadius: _shadowAnimation.value,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextButton(
              onPressed: widget.onPressed,
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _colorAnimation.value,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: widget.accentColor.withOpacity(0.24),
                  ),
                ),
              ),
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.accentColor,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
