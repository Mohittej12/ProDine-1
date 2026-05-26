import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pro_dine/core/widgets/app_logo.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';
import 'package:pro_dine/features/employee/data/employee_favorites_store.dart';
import 'package:pro_dine/features/employee/widgets/employee_cart_overlay.dart';

/// Custom scroll physics that enables looping/circular scrolling behavior
/// Scrolling up past the top jumps to the bottom, and vice versa
class _LoopingScrollPhysics extends ScrollPhysics {
  const _LoopingScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _LoopingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _LoopingScrollPhysics(
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Let parent handle the simulation first
    final simulation = super.createBallisticSimulation(position, velocity);

    // If we're at the bounds, allow bouncing
    final bool atEdge = (position.pixels <= position.minScrollExtent ||
        position.pixels >= position.maxScrollExtent);

    if (atEdge && velocity != 0.0) {
      return simulation;
    }

    return simulation;
  }
}

class EmployeeMenuFragment extends StatefulWidget {
  const EmployeeMenuFragment({
    super.key,
    this.initialRestaurantName,
    this.initialMealName,
    this.selectionVersion = 0,
  });

  final String? initialRestaurantName;
  final String? initialMealName;
  final int selectionVersion;

  @override
  State<EmployeeMenuFragment> createState() => _EmployeeMenuFragmentState();
}

class _EmployeeMenuFragmentState extends State<EmployeeMenuFragment>
    with TickerProviderStateMixin {
  static const Color _primaryRed = Color(0xFFFF1F1F);
  static const Color _darkText = Color(0xFF101828);
  static const Color _mutedText = Color(0xFF667085);
  static const Color _screenBg = Color(0xFFFFFCF8);
  static const Color _softBorder = Color(0xFFEDEFF3);
  static const Color _green = Color(0xFF12B76A);

  static const String _menuImagePath = 'assets/images/auth_login_header.png';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey _mainCartIconKey = GlobalKey();
  final GlobalKey _stickyCartIconKey = GlobalKey();
  final ValueNotifier<double> _stickyHeaderProgress = ValueNotifier<double>(0);

  int _selectedRestaurant = 0;
  int _selectedMeal = 0;
  String _searchQuery = '';
  bool _vegOnly = false;
  bool _availableOnly = true;
  int _cartCount = EmployeeCartStore.instance.itemCount;

  late final AnimationController _cartBounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _cartBounceAnim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.92), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.04), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 20),
  ]).animate(
    CurvedAnimation(
      parent: _cartBounceController,
      curve: Curves.easeOutCubic,
    ),
  );

  String get _selectedRestaurantName =>
      _selectedRestaurant == 0 ? 'Meal Counter' : 'Tuck Shop';

  List<String> get _activeMealTabs =>
      _selectedRestaurant == 0 ? _mealTabsMealCounter : _mealTabsTuckShop;

  String get _selectedMealName => _activeMealTabs[_selectedMeal];

  bool get _hasFilters =>
      _vegOnly || !_availableOnly || _searchQuery.isNotEmpty;

  List<_MenuItemData> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    return _menuItems.where((item) {
      final matchesRestaurant = item.restaurant == _selectedRestaurantName;
      final matchesMeal = item.meal == _selectedMealName;
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final matchesVeg = !_vegOnly || item.isVeg;
      final matchesAvailability = !_availableOnly || item.isAvailable;

      return matchesRestaurant &&
          matchesMeal &&
          matchesSearch &&
          matchesVeg &&
          matchesAvailability;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _applyInitialSelection();
    EmployeeCartStore.instance.addListener(_handleCartChanged);
    _scrollController.addListener(_handleScroll);
    _scrollController.addListener(_handleCircularScroll);
  }

  @override
  void didUpdateWidget(covariant EmployeeMenuFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRestaurantName != widget.initialRestaurantName ||
        oldWidget.initialMealName != widget.initialMealName ||
        oldWidget.selectionVersion != widget.selectionVersion) {
      _applyInitialSelection();
    }
  }

  void _applyInitialSelection() {
    final restaurant = widget.initialRestaurantName;
    final meal = widget.initialMealName;

    // Only pre-select restaurant if explicitly specified (non-empty string)
    if (restaurant == 'Tuck Shop') {
      _selectedRestaurant = 1;
    } else if (restaurant == 'Meal Counter') {
      _selectedRestaurant = 0;
    }
    // If restaurant is empty or null, show first restaurant by default (already 0)

    if (meal != null) {
      final mealIndex = _activeMealTabs.indexOf(meal);
      if (mealIndex != -1) _selectedMeal = mealIndex;
    } else {
      _selectedMeal = 0;
    }
    _selectedMeal = _selectedMeal.clamp(0, _activeMealTabs.length - 1);

    _searchQuery = '';
    _searchController.clear();
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final cartBox =
        _mainCartIconKey.currentContext?.findRenderObject() as RenderBox?;
    final mediaQuery = MediaQuery.maybeOf(context);

    double nextProgress;

    if (cartBox != null && cartBox.attached) {
      final cartBottom =
          cartBox.localToGlobal(Offset(0, cartBox.size.height)).dy;
      final statusBarBottom = mediaQuery?.viewPadding.top ?? 0;
      nextProgress =
          ((statusBarBottom - cartBottom) / 34).clamp(0.0, 1.0).toDouble();
    } else {
      nextProgress = (_scrollController.offset > 120) ? 1 : 0;
    }

    if ((nextProgress - _stickyHeaderProgress.value).abs() > 0.01 ||
        nextProgress == 0 ||
        nextProgress == 1) {
      _stickyHeaderProgress.value = nextProgress;
    }
  }

  /// Handles circular/looping scroll behavior
  /// When user scrolls past the bottom, jumps to top
  /// When user scrolls past the top, jumps to bottom
  void _handleCircularScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    // If we're very close to the bottom, jump to top with animation
    if (currentScroll >= maxScroll - 20 && maxScroll > 0) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
    // If we're at the top and user is trying to scroll up, jump to bottom
    else if (currentScroll <= 20 && maxScroll > 0) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    EmployeeCartStore.instance.removeListener(_handleCartChanged);
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..removeListener(_handleCircularScroll)
      ..dispose();
    _stickyHeaderProgress.dispose();
    _cartBounceController.dispose();
    super.dispose();
  }

  void _handleCartChanged() {
    if (!mounted) return;

    final nextCount = EmployeeCartStore.instance.itemCount;
    if (nextCount == _cartCount && nextCount != 0) return;

    setState(() {
      _cartCount = nextCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _screenBg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = _MenuLayout.fromSize(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          final topSafe = MediaQuery.of(context).padding.top;
          final bottomSafe = MediaQuery.of(context).padding.bottom;

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPadding,
                      layout.topPadding,
                      layout.horizontalPadding,
                      layout.bottomPadding + bottomSafe,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: layout.maxContentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MainHeader(
                                layout: layout,
                                cartCount: _cartCount,
                                cartIconKey: _mainCartIconKey,
                                cartBounceAnim: _cartBounceAnim,
                                onCartTap: () =>
                                    showEmployeeCartSwitcher(context),
                              ),
                              SizedBox(height: layout.headerGap),
                              _MenuControlPanel(
                                layout: layout,
                                selectedRestaurant: _selectedRestaurant,
                                selectedMeal: _selectedMeal,
                                mealTabs: _activeMealTabs,
                                searchController: _searchController,
                                searchQuery: _searchQuery,
                                hasFilters: _hasFilters,
                                onRestaurantChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedRestaurant = index;
                                    _selectedMeal = 0;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                                onClear: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                onFilterTap: () =>
                                    _openFilters(context, layout),
                                onMealChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedMeal = index;
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              ),
                              if (_vegOnly || !_availableOnly) ...[
                                SizedBox(height: 10 * layout.scale),
                                _ActiveFiltersRow(
                                  vegOnly: _vegOnly,
                                  availableOnly: _availableOnly,
                                ),
                              ],
                              SizedBox(height: layout.sectionGap),
                              _SectionHeader(
                                layout: layout,
                                title: _selectedMealName,
                                restaurant: _selectedRestaurantName,
                                count: _filteredItems.length,
                              ),
                              SizedBox(height: layout.gridTopGap),
                              _MenuGrid(
                                layout: layout,
                                items: _filteredItems,
                                onAddToCart: (item, sourceOffset) =>
                                    _addToCart(item, sourceOffset),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<double>(
                  valueListenable: _stickyHeaderProgress,
                  builder: (context, progress, _) {
                    final easedProgress = Curves.easeOutCubic.transform(
                      progress,
                    );

                    return IgnorePointer(
                      ignoring: progress < 0.85,
                      child: Transform.translate(
                        offset: Offset(0, -18 * (1 - easedProgress)),
                        child: Opacity(
                          opacity: easedProgress,
                          child: _StickyHeader(
                            layout: layout,
                            topSafe: topSafe,
                            restaurant: _selectedRestaurantName,
                            meal: _selectedMealName,
                            cartCount: _cartCount,
                            cartIconKey: _stickyCartIconKey,
                            cartBounceAnim: _cartBounceAnim,
                            onCartTap: () => showEmployeeCartSwitcher(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilters(BuildContext context, _MenuLayout layout) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _FilterSheet(
          layout: layout,
          vegOnly: _vegOnly,
          availableOnly: _availableOnly,
        );
      },
    );

    if (result == null) return;

    setState(() {
      _vegOnly = result.vegOnly;
      _availableOnly = result.availableOnly;
    });
  }

  void _addToCart(_MenuItemData item, Offset sourceOffset) {
    if (!item.isAvailable) return;

    final cartItems = EmployeeCartStore.instance.items;

    if (cartItems.isNotEmpty && cartItems.first.shopName != item.restaurant) {
      _showCafeteriaConflictDialog(item, sourceOffset);
      return;
    }

    if (cartItems.isNotEmpty &&
        cartItems.first.shopName == 'Meal Counter' &&
        item.restaurant == 'Meal Counter' &&
        cartItems.first.meal != item.meal) {
      _showMealTimingConflictDialog(item, sourceOffset);
      return;
    }

    EmployeeCartStore.instance.addItem(
      id: _cartIdFor(item),
      name: item.name,
      shopName: item.restaurant,
      meal: item.meal,
      price: _priceToInt(item.price),
      imagePath: item.imagePath,
    );

    _flyToCart(sourceOffset, item.imagePath);
  }

  Future<void> _showCafeteriaConflictDialog(
    _MenuItemData item,
    Offset sourceOffset,
  ) async {
    final currentShopName = EmployeeCartStore.instance.items.first.shopName;
    final confirmed = await _showBookingConflictDialog(
      title: 'Different Cafeteria',
      subtitle: 'Separate vendor order',
      description:
          'You already have items from $currentShopName in your cart. A single order can only contain items from one cafeteria.',
      details:
          'Clear the current cart to start a new order from ${item.restaurant}.',
      actionLabel: 'Switch to ${item.restaurant}',
      icon: Icons.storefront_rounded,
      iconColor: _primaryRed,
    );

    if (confirmed != true) return;

    EmployeeCartStore.instance.clear();
    EmployeeCartStore.instance.addItem(
      id: _cartIdFor(item),
      name: item.name,
      shopName: item.restaurant,
      meal: item.meal,
      price: _priceToInt(item.price),
      imagePath: item.imagePath,
    );

    _flyToCart(sourceOffset, item.imagePath);
  }

  Future<void> _showMealTimingConflictDialog(
    _MenuItemData item,
    Offset sourceOffset,
  ) async {
    final currentMeal = EmployeeCartStore.instance.items.first.meal;
    final confirmed = await _showBookingConflictDialog(
      title: 'Meal Timing Conflict',
      subtitle: 'Breakfast, lunch & dinner are separate slots',
      description:
          'Your cart already contains $currentMeal items from Meal Counter. Each meal has its own service window and cannot be mixed in one order.',
      details: 'Clear the current $currentMeal cart to switch to ${item.meal}.',
      actionLabel: 'Switch to ${item.meal}',
      icon: Icons.schedule_rounded,
      iconColor: _green,
    );

    if (confirmed != true) return;

    EmployeeCartStore.instance.clear();
    EmployeeCartStore.instance.addItem(
      id: _cartIdFor(item),
      name: item.name,
      shopName: item.restaurant,
      meal: item.meal,
      price: _priceToInt(item.price),
      imagePath: item.imagePath,
    );

    _flyToCart(sourceOffset, item.imagePath);
  }

  Future<bool?> _showBookingConflictDialog({
    required String title,
    required String subtitle,
    required String description,
    required String details,
    required String actionLabel,
    required IconData icon,
    required Color iconColor,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Booking conflict',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, __) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  color: Colors.white,
                  elevation: 24,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.14),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: iconColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: _mutedText,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          details,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5A5F69),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _darkText,
                                  side: BorderSide(color: _softBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Keep current cart'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryRed,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(actionLabel),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  String _cartIdFor(_MenuItemData item) {
    final restaurant = item.restaurant.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
    final meal = item.meal.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final name = item.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return '$restaurant-$meal-$name';
  }

  int _priceToInt(String price) {
    final digits = RegExp(r'\d+').allMatches(price).map((m) => m.group(0)!);
    return int.tryParse(digits.join()) ?? 0;
  }

  GlobalKey get _activeCartKey {
    final stickyRender = _stickyCartIconKey.currentContext?.findRenderObject();

    if (_stickyHeaderProgress.value > 0.6 &&
        stickyRender is RenderBox &&
        stickyRender.attached) {
      return _stickyCartIconKey;
    }

    return _mainCartIconKey;
  }

  void _flyToCart(Offset sourceOffset, String imagePath) {
    final cartBox =
        _activeCartKey.currentContext?.findRenderObject() as RenderBox?;

    if (cartBox == null || !cartBox.attached) return;

    final cartPos = cartBox.localToGlobal(
      Offset(cartBox.size.width / 2, cartBox.size.height / 2),
    );

    final overlay = Overlay.of(context);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );

    final curvedAnim = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        return AnimatedBuilder(
          animation: curvedAnim,
          builder: (context, child) {
            final t = curvedAnim.value;

            final dx = sourceOffset.dx + (cartPos.dx - sourceOffset.dx) * t;
            final arcHeight = -118.0 * (1 - math.pow(2 * t - 1, 2));
            final dy = sourceOffset.dy +
                (cartPos.dy - sourceOffset.dy) * t +
                arcHeight;

            final scale = 1.0 - (t * 0.66);
            final opacity = (1.0 - math.pow(t, 2.35)).clamp(0.0, 1.0);

            return Positioned(
              left: dx - 22 * scale,
              top: dy - 22 * scale,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _primaryRed.withOpacity(0.34),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_1, _2, _3) => const Icon(
                          Icons.restaurant_rounded,
                          color: _primaryRed,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    controller.forward().then((_) {
      entry.remove();
      controller.dispose();
      if (!mounted) return;
      _cartBounceController.forward(from: 0);
      setState(() => _cartCount = EmployeeCartStore.instance.itemCount);
    });
  }
}

class _MenuLayout {
  const _MenuLayout({
    required this.isDesktop,
    required this.isTablet,
    required this.isShort,
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.scale,
    required this.headerGap,
    required this.controlGap,
    required this.sectionGap,
    required this.gridTopGap,
    required this.gridColumns,
    required this.gridSpacing,
  });

  final bool isDesktop;
  final bool isTablet;
  final bool isShort;
  final double maxContentWidth;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double scale;
  final double headerGap;
  final double controlGap;
  final double sectionGap;
  final double gridTopGap;
  final int gridColumns;
  final double gridSpacing;

  static _MenuLayout fromSize(double width, double height) {
    final isShort = height < 720;

    if (width >= 1180) {
      return const _MenuLayout(
        isDesktop: true,
        isTablet: false,
        isShort: false,
        maxContentWidth: 1180,
        horizontalPadding: 48,
        topPadding: 26,
        bottomPadding: 72,
        scale: 1,
        headerGap: 14,
        controlGap: 9,
        sectionGap: 20,
        gridTopGap: 14,
        gridColumns: 4,
        gridSpacing: 22,
      );
    }

    if (width >= 760) {
      return const _MenuLayout(
        isDesktop: false,
        isTablet: true,
        isShort: false,
        maxContentWidth: 760,
        horizontalPadding: 34,
        topPadding: 24,
        bottomPadding: 92,
        scale: 1,
        headerGap: 13,
        controlGap: 9,
        sectionGap: 20,
        gridTopGap: 14,
        gridColumns: 3,
        gridSpacing: 20,
      );
    }

    final veryNarrow = width < 345;
    final narrow = width < 370;

    final scale = veryNarrow
        ? 0.88
        : narrow
            ? 0.94
            : 1.0;

    return _MenuLayout(
      isDesktop: false,
      isTablet: false,
      isShort: isShort,
      maxContentWidth: 430,
      horizontalPadding: narrow ? 16 : 20,
      topPadding: isShort ? 12 : 17,
      bottomPadding: 154,
      scale: scale,
      headerGap: isShort ? 11 : 13,
      controlGap: isShort ? 8 : 9,
      sectionGap: isShort ? 16 : 18,
      gridTopGap: 12,
      gridColumns: 2,
      gridSpacing: narrow ? 12 : 15,
    );
  }

  double itemImageHeight(double itemWidth) {
    if (isDesktop) return (itemWidth * 0.62).clamp(132.0, 164.0);
    if (isTablet) return (itemWidth * 0.62).clamp(122.0, 154.0);
    return (itemWidth * 0.64).clamp(102.0, 122.0);
  }

  double itemContentHeight(double itemWidth) {
    if (isDesktop) return 104;
    if (isTablet) return 100;
    if (itemWidth < 150) return 90;
    return 94;
  }

  double itemHeight(double itemWidth) {
    return itemImageHeight(itemWidth) + itemContentHeight(itemWidth);
  }

  double cardRadius(double itemWidth) {
    if (isDesktop || isTablet) return 23;
    return itemWidth < 150 ? 19 : 21;
  }
}

class _MainHeader extends StatelessWidget {
  const _MainHeader({
    required this.layout,
    required this.cartCount,
    required this.cartIconKey,
    required this.cartBounceAnim,
    required this.onCartTap,
  });

  final _MenuLayout layout;
  final int cartCount;
  final GlobalKey cartIconKey;
  final Animation<double> cartBounceAnim;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      height: layout.isDesktop ? 48 : 44 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppLogo(
              height: layout.isDesktop ? 21 : 17.5 * scale,
              isBrand: true,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: layout.isDesktop ? 64 : 54 * scale,
            ),
            child: Text(
              'Menu',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _EmployeeMenuFragmentState._darkText,
                fontSize: layout.isDesktop ? 28 : 22.5 * scale,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _CartButton(
              key: cartIconKey,
              layout: layout,
              cartCount: cartCount,
              cartBounceAnim: cartBounceAnim,
              onTap: onCartTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.layout,
    required this.topSafe,
    required this.restaurant,
    required this.meal,
    required this.cartCount,
    required this.cartIconKey,
    required this.cartBounceAnim,
    required this.onCartTap,
  });

  final _MenuLayout layout;
  final double topSafe;
  final String restaurant;
  final String meal;
  final int cartCount;
  final GlobalKey cartIconKey;
  final Animation<double> cartBounceAnim;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          layout.horizontalPadding,
          topSafe + 4,
          layout.horizontalPadding,
          6,
        ),
        decoration: BoxDecoration(
          color: _EmployeeMenuFragmentState._screenBg.withOpacity(0.985),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.085),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -9,
            ),
          ],
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
            child: Container(
              height: layout.isDesktop ? 54 : 47 * scale,
              padding: EdgeInsets.symmetric(horizontal: 10 * scale),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18 * scale),
                border: Border.all(
                  color: _EmployeeMenuFragmentState._softBorder,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppLogo(
                      height: layout.isDesktop ? 19 : 15.5 * scale,
                      isBrand: true,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.isDesktop ? 58 : 50 * scale,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Column(
                        key: ValueKey('$meal-$restaurant'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            meal,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _EmployeeMenuFragmentState._darkText,
                              fontSize: layout.isDesktop ? 16 : 14.2 * scale,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5 * scale),
                          Text(
                            restaurant,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _EmployeeMenuFragmentState._mutedText,
                              fontSize: layout.isDesktop ? 12 : 10.8 * scale,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _CartButton(
                      key: cartIconKey,
                      layout: layout,
                      cartCount: cartCount,
                      cartBounceAnim: cartBounceAnim,
                      onTap: onCartTap,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({
    super.key,
    required this.layout,
    required this.cartCount,
    required this.cartBounceAnim,
    required this.onTap,
    this.compact = false,
  });

  final _MenuLayout layout;
  final int cartCount;
  final Animation<double> cartBounceAnim;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final size = compact
        ? (layout.isDesktop ? 46.0 : 41.0 * scale)
        : (layout.isDesktop ? 46.0 : 42.0 * scale);
    final radius = BorderRadius.circular(compact ? 15 : 14);

    return ScaleTransition(
      scale: cartBounceAnim,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: _EmployeeMenuFragmentState._softBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: _EmployeeMenuFragmentState._darkText,
                  size: compact ? 21 * scale : 21.5 * scale,
                ),
                if (cartCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _EmployeeMenuFragmentState._primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class _MenuControlPanel extends StatelessWidget {
  const _MenuControlPanel({
    required this.layout,
    required this.selectedRestaurant,
    required this.selectedMeal,
    required this.mealTabs,
    required this.searchController,
    required this.searchQuery,
    required this.hasFilters,
    required this.onRestaurantChanged,
    required this.onMealChanged,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  final _MenuLayout layout;
  final int selectedRestaurant;
  final int selectedMeal;
  final List<String> mealTabs;
  final TextEditingController searchController;
  final String searchQuery;
  final bool hasFilters;
  final ValueChanged<int> onRestaurantChanged;
  final ValueChanged<int> onMealChanged;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final panelPadding = layout.isDesktop ? 14.0 : 12 * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(panelPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(layout.isDesktop ? 24 : 20 * scale),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (layout.isDesktop || layout.isTablet) ...[
            Row(
              children: [
                Expanded(
                  flex: 9,
                  child: _RestaurantToggle(
                    layout: layout,
                    selectedIndex: selectedRestaurant,
                    onChanged: onRestaurantChanged,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  flex: 12,
                  child: _SearchFilterBar(
                    layout: layout,
                    controller: searchController,
                    query: searchQuery,
                    hasFilters: hasFilters,
                    onChanged: onChanged,
                    onClear: onClear,
                    onFilterTap: onFilterTap,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14 * scale),
          ] else ...[
            _RestaurantToggle(
              layout: layout,
              selectedIndex: selectedRestaurant,
              onChanged: onRestaurantChanged,
            ),
            SizedBox(height: 11 * scale),
            _SearchFilterBar(
              layout: layout,
              controller: searchController,
              query: searchQuery,
              hasFilters: hasFilters,
              onChanged: onChanged,
              onClear: onClear,
              onFilterTap: onFilterTap,
            ),
            SizedBox(height: 11 * scale),
          ],
          _MealTabs(
            layout: layout,
            tabs: mealTabs,
            selectedIndex: selectedMeal,
            onChanged: onMealChanged,
          ),
        ],
      ),
    );
  }
}

class _RestaurantToggle extends StatelessWidget {
  const _RestaurantToggle({
    required this.layout,
    required this.selectedIndex,
    required this.onChanged,
  });

  final _MenuLayout layout;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Container(
      height: layout.isDesktop ? 56 : 52 * scale,
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Row(
        children: [
          _SegmentOption(
            label: 'Meal Counter',
            icon: Icons.restaurant_menu_rounded,
            selected: selectedIndex == 0,
            scale: scale,
            onTap: () => onChanged(0),
          ),
          _SegmentOption(
            label: 'Tuck Shop',
            icon: Icons.storefront_rounded,
            selected: selectedIndex == 1,
            scale: scale,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox.expand(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14 * scale),
            border: Border.all(
              color: selected
                  ? _EmployeeMenuFragmentState._primaryRed.withValues(
                      alpha: 0.22,
                    )
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -9,
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14 * scale),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 9 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 27 * scale,
                    height: 27 * scale,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFFEFEB)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: _EmployeeMenuFragmentState._primaryRed,
                      size: 16 * scale,
                    ),
                  ),
                  SizedBox(width: 7 * scale),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 160),
                      style: TextStyle(
                        color: selected
                            ? _EmployeeMenuFragmentState._darkText
                            : _EmployeeMenuFragmentState._mutedText,
                        fontSize: 13.1 * scale,
                        height: 1,
                        fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w800,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchFilterBar extends StatelessWidget {
  const _SearchFilterBar({
    required this.layout,
    required this.controller,
    required this.query,
    required this.hasFilters,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  final _MenuLayout layout;
  final TextEditingController controller;
  final String query;
  final bool hasFilters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;
    final height = layout.isDesktop ? 52.0 : 48 * scale;

    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              borderRadius: BorderRadius.circular(17 * scale),
              border: Border.all(
                color: query.isEmpty
                    ? _EmployeeMenuFragmentState._softBorder
                    : _EmployeeMenuFragmentState._primaryRed.withValues(
                        alpha: 0.30,
                      ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.026),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                  spreadRadius: -9,
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: 13 * scale),
                Icon(
                  Icons.search_rounded,
                  color: query.isEmpty
                      ? const Color(0xFF98A2B3)
                      : _EmployeeMenuFragmentState._primaryRed,
                  size: layout.isDesktop ? 23 : 21 * scale,
                ),
                SizedBox(width: 9 * scale),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    cursorColor: _EmployeeMenuFragmentState._primaryRed,
                    textInputAction: TextInputAction.search,
                    scrollPadding: EdgeInsets.zero,
                    style: TextStyle(
                      color: _EmployeeMenuFragmentState._darkText,
                      fontSize: layout.isDesktop ? 14.5 : 13.3 * scale,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search food items...',
                      hintStyle: TextStyle(
                        color: Color(0xFF98A2B3),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 10 * scale),
        Material(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(17 * scale),
          child: InkWell(
            onTap: onFilterTap,
            borderRadius: BorderRadius.circular(17 * scale),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: layout.isDesktop ? 54 : 48 * scale,
              height: height,
              decoration: BoxDecoration(
                color: hasFilters
                    ? const Color(0xFFFFF0EC)
                    : const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(17 * scale),
                border: Border.all(
                  color: hasFilters
                      ? _EmployeeMenuFragmentState._primaryRed.withValues(
                          alpha: 0.34,
                        )
                      : _EmployeeMenuFragmentState._softBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.026),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                    spreadRadius: -9,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: hasFilters
                        ? _EmployeeMenuFragmentState._primaryRed
                        : const Color(0xFF98A2B3),
                    size: layout.isDesktop ? 23 : 20.5 * scale,
                  ),
                  if (hasFilters)
                    Positioned(
                      top: 11,
                      right: 12,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _EmployeeMenuFragmentState._primaryRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MealTabs extends StatelessWidget {
  const _MealTabs({
    required this.layout,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final _MenuLayout layout;
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return SizedBox(
      height: layout.isDesktop ? 42 : 38 * scale,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == tabs.length - 1 ? 0 : 4 * scale,
              ),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(12 * scale),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        selected ? const Color(0xFFFFF1ED) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tabs[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? _EmployeeMenuFragmentState._primaryRed
                              : _EmployeeMenuFragmentState._mutedText,
                          fontSize: 13.2 * scale,
                          height: 1,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34 * scale,
                        height: 3 * scale,
                        decoration: BoxDecoration(
                          color: selected
                              ? _EmployeeMenuFragmentState._primaryRed
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.layout,
    required this.title,
    required this.restaurant,
    required this.count,
  });

  final _MenuLayout layout;
  final String title;
  final String restaurant;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scale = layout.scale;

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              style: TextStyle(
                color: _EmployeeMenuFragmentState._darkText,
                fontSize: layout.isDesktop ? 29 : 22.5 * scale,
                height: 1.08,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.75,
              ),
              children: [
                TextSpan(
                  text: ' • $restaurant',
                  style: TextStyle(
                    color: _EmployeeMenuFragmentState._mutedText,
                    fontSize: layout.isDesktop ? 15 : 12.3 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: 10 * scale),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFEF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count items',
            style: TextStyle(
              color: _EmployeeMenuFragmentState._primaryRed,
              fontSize: 12.3 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({
    required this.layout,
    required this.items,
    required this.onAddToCart,
  });

  final _MenuLayout layout;
  final List<_MenuItemData> items;
  final void Function(_MenuItemData item, Offset sourceOffset) onAddToCart;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.min(layout.gridColumns, items.length);
        final spacing = layout.gridSpacing;
        final totalSpacing = spacing * (columns - 1);
        final availableWidth = constraints.maxWidth;
        final itemWidth = (availableWidth - totalSpacing) / columns;
        final itemHeight = layout.itemHeight(itemWidth);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SizedBox(
            width: availableWidth,
            child: Wrap(
              key: ValueKey('menu-${items.length}-${items.first.name}'),
              spacing: spacing,
              runSpacing: spacing,
              alignment: WrapAlignment.start,
              children: items.map((item) {
                return SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: _MenuItemCard(
                    item: item,
                    layout: layout,
                    itemWidth: itemWidth,
                    onAdd: (offset) => onAddToCart(item, offset),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  const _MenuItemCard({
    required this.item,
    required this.layout,
    required this.itemWidth,
    required this.onAdd,
  });

  final _MenuItemData item;
  final _MenuLayout layout;
  final double itemWidth;
  final void Function(Offset sourceOffset) onAdd;

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final favoriteId = _favoriteIdFor(item);
    final layout = widget.layout;
    final scale = layout.scale;
    final imageHeight = layout.itemImageHeight(widget.itemWidth);
    final radius = layout.cardRadius(widget.itemWidth);

    return Opacity(
      opacity: item.isAvailable ? 1 : 0.62,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: _EmployeeMenuFragmentState._softBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 18,
              offset: const Offset(0, 9),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_1, _2, _3) {
                      return Container(
                        color: const Color(0xFFFFF2EC),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: _EmployeeMenuFragmentState._primaryRed,
                          size: 32,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8 * scale,
                    left: 8 * scale,
                    child: _DietBadge(isVeg: item.isVeg, scale: scale),
                  ),
                  Positioned(
                    top: 8 * scale,
                    right: 8 * scale,
                    child: ValueListenableBuilder<List<EmployeeFavoriteItem>>(
                      valueListenable: EmployeeFavoritesStore.instance,
                      builder: (context, favorites, _) {
                        final favorite = favorites.any(
                          (item) => item.id == favoriteId,
                        );

                        return _CircleIconButton(
                          scale: scale,
                          icon: favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: favorite
                              ? _EmployeeMenuFragmentState._primaryRed
                              : _EmployeeMenuFragmentState._darkText,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            EmployeeFavoritesStore.instance.toggle(
                              EmployeeFavoriteItem(
                                id: favoriteId,
                                name: item.name,
                                price: item.price,
                                description: item.description,
                                restaurant: item.restaurant,
                                meal: item.meal,
                                category: item.category,
                                rating: item.rating,
                                isVeg: item.isVeg,
                                isAvailable: item.isAvailable,
                                imagePath: item.imagePath,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8 * scale,
                    right: 8 * scale,
                    child: _AddButton(
                      enabled: item.isAvailable,
                      size: layout.isDesktop ? 38 : 36 * scale,
                      onTap: (offset) => widget.onAdd(offset),
                    ),
                  ),
                  if (!item.isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.22),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Unavailable',
                            style: TextStyle(
                              color: _EmployeeMenuFragmentState._darkText,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  11.5 * scale,
                  9 * scale,
                  11.5 * scale,
                  8.5 * scale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeMenuFragmentState._darkText,
                        fontSize: layout.isDesktop ? 16 : 14.2 * scale,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.32,
                      ),
                    ),
                    SizedBox(height: 4.5 * scale),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _EmployeeMenuFragmentState._mutedText,
                        fontSize: layout.isDesktop ? 12 : 10.9 * scale,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            item.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _EmployeeMenuFragmentState._primaryRed,
                              fontSize: layout.isDesktop ? 16 : 14.8 * scale,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _favoriteIdFor(_MenuItemData item) {
    return '${item.restaurant}-${item.meal}-${item.name}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }
}

class _DietBadge extends StatelessWidget {
  const _DietBadge({required this.isVeg, required this.scale});

  final bool isVeg;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 7.5 * scale,
        vertical: 5 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: isVeg
                ? _EmployeeMenuFragmentState._green
                : const Color(0xFFFF7A00),
            size: 7.4 * scale,
          ),
          SizedBox(width: 5 * scale),
          Text(
            isVeg ? 'Veg' : 'Non-Veg',
            style: TextStyle(
              color: _EmployeeMenuFragmentState._darkText,
              fontSize: 9.4 * scale,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.scale,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 34 * scale;

    return Material(
      color: Colors.white.withOpacity(0.96),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18.5 * scale, color: color),
        ),
      ),
    );
  }
}

class _AddButton extends StatefulWidget {
  const _AddButton({
    required this.enabled,
    required this.size,
    required this.onTap,
  });

  final bool enabled;
  final double size;
  final void Function(Offset globalCenter) onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> with TickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 1.0,
    end: 0.88,
  ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        key: _buttonKey,
        color: widget.enabled
            ? _EmployeeMenuFragmentState._primaryRed
            : const Color(0xFFBDBDBD),
        shape: const CircleBorder(),
        elevation: 7,
        shadowColor: _EmployeeMenuFragmentState._primaryRed.withValues(
          alpha: 0.28,
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.enabled
              ? () async {
                  HapticFeedback.lightImpact();

                  await _pressController.forward();
                  await _pressController.reverse();

                  final box = _buttonKey.currentContext?.findRenderObject()
                      as RenderBox?;
                  if (box == null) return;

                  final center = box.localToGlobal(
                    Offset(box.size.width / 2, box.size.height / 2),
                  );

                  widget.onTap(center);
                }
              : null,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: widget.size * 0.68,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({required this.vegOnly, required this.availableOnly});

  final bool vegOnly;
  final bool availableOnly;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (vegOnly) const _ActiveChip(label: 'Veg only'),
        if (!availableOnly) const _ActiveChip(label: 'Showing unavailable'),
      ],
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _EmployeeMenuFragmentState._primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.layout,
    required this.vegOnly,
    required this.availableOnly,
  });

  final _MenuLayout layout;
  final bool vegOnly;
  final bool availableOnly;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _vegOnly = widget.vegOnly;
  late bool _availableOnly = widget.availableOnly;

  @override
  Widget build(BuildContext context) {
    final desktopSheet = widget.layout.isDesktop || widget.layout.isTablet;

    return Align(
      alignment: desktopSheet ? Alignment.centerRight : Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: desktopSheet ? 420 : double.infinity,
        ),
        child: Container(
          margin: EdgeInsets.only(
            right: desktopSheet ? 28 : 0,
            top: desktopSheet ? 28 : 0,
            bottom: desktopSheet ? 28 : 0,
          ),
          padding: EdgeInsets.fromLTRB(
            22,
            14,
            22,
            22 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: Radius.circular(desktopSheet ? 28 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          color: _EmployeeMenuFragmentState._darkText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _vegOnly = false;
                          _availableOnly = true;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: _EmployeeMenuFragmentState._primaryRed,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SwitchTile(
                  title: 'Veg only',
                  subtitle: 'Show only vegetarian items',
                  value: _vegOnly,
                  onChanged: (value) => setState(() => _vegOnly = value),
                ),
                const SizedBox(height: 10),
                _SwitchTile(
                  title: 'Available only',
                  subtitle: 'Hide sold out items',
                  value: _availableOnly,
                  onChanged: (value) => setState(() => _availableOnly = value),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _FilterResult(
                          vegOnly: _vegOnly,
                          availableOnly: _availableOnly,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _EmployeeMenuFragmentState._primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _EmployeeMenuFragmentState._darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _EmployeeMenuFragmentState._mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: _EmployeeMenuFragmentState._primaryRed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: _EmployeeMenuFragmentState._primaryRed,
            size: 36,
          ),
          SizedBox(height: 10),
          Text(
            'No items found',
            style: TextStyle(
              color: _EmployeeMenuFragmentState._darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try another restaurant, meal type, or filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _EmployeeMenuFragmentState._mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({required this.vegOnly, required this.availableOnly});

  final bool vegOnly;
  final bool availableOnly;
}

class _MenuItemData {
  const _MenuItemData({
    required this.name,
    required this.price,
    required this.description,
    required this.restaurant,
    required this.meal,
    required this.category,
    required this.rating,
    required this.isVeg,
    required this.isAvailable,
    required this.imagePath,
  });

  final String name;
  final String price;
  final String description;
  final String restaurant;
  final String meal;
  final String category;
  final String rating;
  final bool isVeg;
  final bool isAvailable;
  final String imagePath;
}

const List<String> _mealTabsMealCounter = ['Breakfast', 'Lunch', 'Dinner'];
const List<String> _mealTabsTuckShop = ['Juices', 'Beverages'];

const List<_MenuItemData> _menuItems = [
  _MenuItemData(
    name: 'Idli',
    price: '₹60',
    description: 'Soft steamed rice cakes',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'South Indian',
    rating: '4.7',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Upma',
    price: '₹55',
    description: 'Warm savory semolina breakfast',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'South Indian',
    rating: '4.5',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Dosa',
    price: '₹80',
    description: 'Crispy dosa with chutney',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'South Indian',
    rating: '4.8',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Poori',
    price: '₹70',
    description: 'Fluffy poori with curry',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'South Indian',
    rating: '4.6',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Pongal',
    price: '₹65',
    description: 'Ghee pongal with chutney',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'South Indian',
    rating: '4.6',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Vada',
    price: '₹45',
    description: 'Crispy lentil vada',
    restaurant: 'Meal Counter',
    meal: 'Breakfast',
    category: 'South Indian',
    rating: '4.4',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Veg Meals',
    price: '₹140',
    description: 'Rice, curry, dal and sides',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Meals',
    rating: '4.7',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Chicken Biryani',
    price: '₹220',
    description: 'Spiced rice with chicken',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Biryani',
    rating: '4.9',
    isVeg: false,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Curd Rice',
    price: '₹90',
    description: 'Comfort curd rice bowl',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Meals',
    rating: '4.4',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Paneer Rice',
    price: '₹165',
    description: 'Paneer curry rice bowl',
    restaurant: 'Meal Counter',
    meal: 'Lunch',
    category: 'Meals',
    rating: '4.6',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Chapati Curry',
    price: '₹110',
    description: 'Chapati with fresh curry',
    restaurant: 'Meal Counter',
    meal: 'Dinner',
    category: 'Dinner',
    rating: '4.5',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Fried Rice',
    price: '₹160',
    description: 'Hot wok-style fried rice',
    restaurant: 'Meal Counter',
    meal: 'Dinner',
    category: 'Rice',
    rating: '4.6',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Orange Juice',
    price: '₹70',
    description: 'Freshly squeezed orange juice',
    restaurant: 'Tuck Shop',
    meal: 'Juices',
    category: 'Juices',
    rating: '4.6',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Watermelon Juice',
    price: '₹75',
    description: 'Chilled watermelon cooler',
    restaurant: 'Tuck Shop',
    meal: 'Juices',
    category: 'Juices',
    rating: '4.5',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Pineapple Juice',
    price: '₹80',
    description: 'Cold tropical pineapple blend',
    restaurant: 'Tuck Shop',
    meal: 'Juices',
    category: 'Juices',
    rating: '4.7',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Coffee',
    price: '₹45',
    description: 'Fresh brewed coffee',
    restaurant: 'Tuck Shop',
    meal: 'Beverages',
    category: 'Beverage',
    rating: '4.6',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Tea',
    price: '₹25',
    description: 'Hot cafeteria tea',
    restaurant: 'Tuck Shop',
    meal: 'Beverages',
    category: 'Beverage',
    rating: '4.3',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Lemon Soda',
    price: '₹55',
    description: 'Sparkling lemon soda',
    restaurant: 'Tuck Shop',
    meal: 'Beverages',
    category: 'Beverage',
    rating: '4.4',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Cold Coffee',
    price: '₹90',
    description: 'Creamy chilled cold coffee',
    restaurant: 'Tuck Shop',
    meal: 'Beverages',
    category: 'Beverage',
    rating: '4.5',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
  _MenuItemData(
    name: 'Buttermilk',
    price: '₹35',
    description: 'Spiced chilled buttermilk',
    restaurant: 'Tuck Shop',
    meal: 'Beverages',
    category: 'Beverage',
    rating: '4.2',
    isVeg: true,
    isAvailable: true,
    imagePath: _EmployeeMenuFragmentState._menuImagePath,
  ),
];
