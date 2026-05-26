import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_colors.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/core/widgets/app_button.dart';
import 'package:pro_dine/core/widgets/app_text_field.dart';
import 'package:pro_dine/features/employee/data/employee_cart_store.dart';

class AuthLoginPage extends StatefulWidget {
  const AuthLoginPage({super.key});

  @override
  State<AuthLoginPage> createState() => _AuthLoginPageState();
}

enum _AuthRole { employee, vendor, admin }

class _AuthLoginPageState extends State<AuthLoginPage> {
  bool _agreeToTerms = false;
  _AuthRole _currentRole = _AuthRole.employee;

  bool get _isVendor => _currentRole == _AuthRole.vendor;
  bool get _isAdmin => _currentRole == _AuthRole.admin;

  String get _heroImage {
    if (_isVendor) {
      return 'assets/images/auth_dining_detailed_line_art_png_1778509028286.png';
    }

    if (_isAdmin) {
      return 'assets/images/auth_dining_detailed_line_art_png_1778509028286.png';
    }

    return 'assets/images/auth_login_header.png';
  }

  String get _title {
    if (_isVendor) return 'Vendor Login';
    if (_isAdmin) return 'Admin Login';
    return 'Employee Login';
  }

  String get _subtitle {
    if (_isVendor) return 'Manage orders, menu items, and daily operations.';
    if (_isAdmin) return 'Monitor cafeteria performance and business reports.';
    return 'Order fresh meals faster inside Pro Dine.';
  }

  String get _primaryAction {
    if (_isVendor) return 'Sign in as Vendor';
    if (_isAdmin) return 'Sign in as Admin';
    return 'Sign In';
  }

  String get _identifierHint {
    return 'Mobile number';
  }

  TextInputType get _identifierKeyboard {
    return TextInputType.phone;
  }

  IconData get _identifierIcon {
    return Icons.phone_android_rounded;
  }

  void _handleSignIn() {
    if (_isVendor) {
      context.push(AppRoutes.vendorDashboard);
      return;
    }

    if (_isAdmin) {
      context.push(AppRoutes.adminDashboard);
      return;
    }

    // Clear cart on fresh employee login
    EmployeeCartStore.instance.clear();
    context.push(AppRoutes.employeeModeSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final isWide = width >= 900;
            final isTablet = width >= 650 && width < 900;
            final compactHeight = height < 720;
            final veryCompactHeight = height < 620;

            final horizontalPadding = isWide
                ? 28.0
                : isTablet
                    ? 24.0
                    : 16.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? horizontalPadding : 0,
                vertical: isWide ? 20 : 0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1220),
                  child: isWide
                      ? _WideAuthLayout(
                          heroImage: _heroImage,
                          title: _title,
                          subtitle: _subtitle,
                          currentRole: _currentRole,
                          compactHeight: compactHeight,
                          veryCompactHeight: veryCompactHeight,
                          identifierHint: _identifierHint,
                          identifierKeyboard: _identifierKeyboard,
                          identifierIcon: _identifierIcon,
                          primaryAction: _primaryAction,
                          agreeToTerms: _agreeToTerms,
                          onRoleChanged: (role) {
                            setState(() => _currentRole = role);
                          },
                          onTermsChanged: (value) {
                            setState(() => _agreeToTerms = value ?? false);
                          },
                          onSignIn: _handleSignIn,
                        )
                      : _MobileAuthLayout(
                          heroImage: _heroImage,
                          title: _title,
                          subtitle: _subtitle,
                          currentRole: _currentRole,
                          compactHeight: compactHeight,
                          veryCompactHeight: veryCompactHeight,
                          identifierHint: _identifierHint,
                          identifierKeyboard: _identifierKeyboard,
                          identifierIcon: _identifierIcon,
                          primaryAction: _primaryAction,
                          agreeToTerms: _agreeToTerms,
                          onRoleChanged: (role) {
                            setState(() => _currentRole = role);
                          },
                          onTermsChanged: (value) {
                            setState(() => _agreeToTerms = value ?? false);
                          },
                          onSignIn: _handleSignIn,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WideAuthLayout extends StatelessWidget {
  final String heroImage;
  final String title;
  final String subtitle;
  final _AuthRole currentRole;
  final bool compactHeight;
  final bool veryCompactHeight;
  final String identifierHint;
  final TextInputType identifierKeyboard;
  final IconData identifierIcon;
  final String primaryAction;
  final bool agreeToTerms;
  final ValueChanged<_AuthRole> onRoleChanged;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSignIn;

  const _WideAuthLayout({
    required this.heroImage,
    required this.title,
    required this.subtitle,
    required this.currentRole,
    required this.compactHeight,
    required this.veryCompactHeight,
    required this.identifierHint,
    required this.identifierKeyboard,
    required this.identifierIcon,
    required this.primaryAction,
    required this.agreeToTerms,
    required this.onRoleChanged,
    required this.onTermsChanged,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 11,
          child: _HeroPanel(imagePath: heroImage, compactHeight: compactHeight),
        ),
        const SizedBox(width: 28),
        Expanded(
          flex: 9,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _LoginCard(
                title: title,
                subtitle: subtitle,
                currentRole: currentRole,
                compactHeight: compactHeight,
                veryCompactHeight: veryCompactHeight,
                identifierHint: identifierHint,
                identifierKeyboard: identifierKeyboard,
                identifierIcon: identifierIcon,
                primaryAction: primaryAction,
                agreeToTerms: agreeToTerms,
                onRoleChanged: onRoleChanged,
                onTermsChanged: onTermsChanged,
                onSignIn: onSignIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileAuthLayout extends StatelessWidget {
  final String heroImage;
  final String title;
  final String subtitle;
  final _AuthRole currentRole;
  final bool compactHeight;
  final bool veryCompactHeight;
  final String identifierHint;
  final TextInputType identifierKeyboard;
  final IconData identifierIcon;
  final String primaryAction;
  final bool agreeToTerms;
  final ValueChanged<_AuthRole> onRoleChanged;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSignIn;

  const _MobileAuthLayout({
    required this.heroImage,
    required this.title,
    required this.subtitle,
    required this.currentRole,
    required this.compactHeight,
    required this.veryCompactHeight,
    required this.identifierHint,
    required this.identifierKeyboard,
    required this.identifierIcon,
    required this.primaryAction,
    required this.agreeToTerms,
    required this.onRoleChanged,
    required this.onTermsChanged,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final heroHeight = veryCompactHeight
            ? availableHeight * 0.28
            : compactHeight
                ? availableHeight * 0.32
                : availableHeight * 0.38;

        return Stack(
          children: [
            // Full-bleed image at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: heroHeight + 80, // Extend more for the overlap
              child: _HeroPanel(
                imagePath: heroImage,
                compactHeight: compactHeight,
                fullBleed: true,
              ),
            ),

            // Overlapping Card
            Positioned(
              top: heroHeight - 40, // Move more top for deeper overlap
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                clipBehavior: Clip
                    .antiAlias, // Ensure children respect the rounded corners
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(54),
                    topRight: Radius.circular(54),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 40,
                      offset: Offset(0, -12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: _LoginCard(
                      title: title,
                      subtitle: subtitle,
                      currentRole: currentRole,
                      compactHeight: compactHeight,
                      veryCompactHeight: veryCompactHeight,
                      identifierHint: identifierHint,
                      identifierKeyboard: identifierKeyboard,
                      identifierIcon: identifierIcon,
                      primaryAction: primaryAction,
                      agreeToTerms: agreeToTerms,
                      onRoleChanged: onRoleChanged,
                      onTermsChanged: onTermsChanged,
                      onSignIn: onSignIn,
                      isFullPage: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String imagePath;
  final bool compactHeight;
  final bool fullBleed;

  const _HeroPanel({
    required this.imagePath,
    required this.compactHeight,
    this.fullBleed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE9),
        borderRadius: fullBleed
            ? BorderRadius.zero
            : BorderRadius.circular(compactHeight ? 24 : 32),
        border: fullBleed ? null : Border.all(color: const Color(0xFFFFDED4)),
        boxShadow: fullBleed
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!fullBleed)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFFF7F2),
                      AppColors.primaryRed.withOpacity(0.08),
                      const Color(0xFFFFE6DB),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: fullBleed
                ? EdgeInsets.zero
                : EdgeInsets.all(compactHeight ? 10 : 18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: Image.asset(
                imagePath,
                key: ValueKey(imagePath),
                fit: fullBleed ? BoxFit.cover : BoxFit.contain,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const _HeroFallback();
                },
              ),
            ),
          ),
          if (!fullBleed)
            Positioned(
              left: compactHeight ? 14 : 22,
              bottom: compactHeight ? 12 : 20,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compactHeight ? 10 : 14,
                  vertical: compactHeight ? 7 : 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pro Dine',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: compactHeight ? 11.5 : 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: 84,
        color: AppColors.primaryRed.withOpacity(0.22),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final _AuthRole currentRole;
  final bool compactHeight;
  final bool veryCompactHeight;
  final String identifierHint;
  final TextInputType identifierKeyboard;
  final IconData identifierIcon;
  final String primaryAction;
  final bool agreeToTerms;
  final ValueChanged<_AuthRole> onRoleChanged;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSignIn;
  final bool isFullPage;

  const _LoginCard({
    required this.title,
    required this.subtitle,
    required this.currentRole,
    required this.compactHeight,
    required this.veryCompactHeight,
    required this.identifierHint,
    required this.identifierKeyboard,
    required this.identifierIcon,
    required this.primaryAction,
    required this.agreeToTerms,
    required this.onRoleChanged,
    required this.onTermsChanged,
    required this.onSignIn,
    this.isFullPage = false,
  });

  bool get _isEmployee => currentRole == _AuthRole.employee;

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    if (!widget.agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms before signing in.'),
        ),
      );
      return;
    }
    widget.onSignIn();
  }

  void _openTermsPage() {
    final route = widget.currentRole == _AuthRole.employee
        ? AppRoutes.employeeTerms
        : widget.currentRole == _AuthRole.vendor
            ? AppRoutes.vendorTerms
            : AppRoutes.adminTerms;
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final cardPadding = widget.veryCompactHeight
        ? 16.0
        : widget.compactHeight
            ? 18.0
            : 24.0;

    final logoHeight = widget.veryCompactHeight
        ? 52.0
        : widget.compactHeight
            ? 60.0
            : 76.0;

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: widget.isFullPage
            ? null
            : BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(widget.compactHeight ? 26 : 32),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ProDine',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: logoHeight * 0.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: widget.veryCompactHeight ? 10 : 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Column(
                key: ValueKey(widget.subtitle),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: widget.compactHeight ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: widget.veryCompactHeight ? 12 : 18),
            _RoleSelector(
              currentRole: widget.currentRole,
              onChanged: widget.onRoleChanged,
              compact: widget.compactHeight,
            ),
            SizedBox(height: widget.veryCompactHeight ? 12 : 18),
            AppTextField(
              controller: _mobileController,
              hint: widget.identifierHint,
              keyboardType: widget.identifierKeyboard,
              obscureText: false,
              prefixIcon: Icon(widget.identifierIcon),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your mobile number';
                }
                final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length != 10) {
                  return 'Mobile number must be exactly 10 digits';
                }
                return null;
              },
            ),
            SizedBox(height: widget.veryCompactHeight ? 10 : 14),
            AppTextField(
              controller: _passwordController,
              hint: 'Password',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Password must contain at least one uppercase letter';
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'Password must contain at least one lowercase letter';
                }
                return null;
              },
            ),
            SizedBox(height: widget.veryCompactHeight ? 8 : 10),
            Row(
              children: [
                Expanded(
                  child: _TermsCheckbox(
                    value: widget.agreeToTerms,
                    onChanged: widget.onTermsChanged,
                    onLinkTap: _openTermsPage,
                    compact: widget.compactHeight,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.compactHeight ? 6 : 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot?',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: widget.compactHeight ? 12 : 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.veryCompactHeight ? 12 : 16),
            AppButton(text: widget.primaryAction, onPressed: _submit),
            if (widget._isEmployee) ...[
              SizedBox(height: widget.veryCompactHeight ? 10 : 14),
              _CreateAccountLink(compact: widget.compactHeight),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final _AuthRole currentRole;
  final ValueChanged<_AuthRole> onChanged;
  final bool compact;

  const _RoleSelector({
    required this.currentRole,
    required this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 4 : 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFDDD2)),
      ),
      child: Row(
        children: [
          _RoleChip(
            label: 'Employee',
            selected: currentRole == _AuthRole.employee,
            compact: compact,
            onTap: () => onChanged(_AuthRole.employee),
          ),
          _RoleChip(
            label: 'Vendor',
            selected: currentRole == _AuthRole.vendor,
            compact: compact,
            onTap: () => onChanged(_AuthRole.vendor),
          ),
          _RoleChip(
            label: 'Admin',
            selected: currentRole == _AuthRole.admin,
            compact: compact,
            onTap: () => onChanged(_AuthRole.admin),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: compact ? 8 : 10,
                horizontal: compact ? 4 : 6,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final bool compact;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onLinkTap;

  const _TermsCheckbox({
    required this.value,
    required this.compact,
    required this.onChanged,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: compact ? 20 : 22,
          width: compact ? 20 : 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryRed,
            side: BorderSide(
              color: AppColors.primaryRed.withOpacity(0.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              Text(
                'I agree to ',
                style: TextStyle(
                  fontSize: compact ? 11.2 : 12.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
              InkWell(
                onTap: onLinkTap,
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'Terms',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11.2 : 12.2,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                ' & ',
                style: TextStyle(
                  fontSize: compact ? 11.2 : 12.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.2,
                ),
              ),
              InkWell(
                onTap: onLinkTap,
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'Disclaimer',
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11.2 : 12.2,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreateAccountLink extends StatelessWidget {
  final bool compact;

  const _CreateAccountLink({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      children: [
        Text(
          'New to Pro Dine?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        InkWell(
          onTap: () => context.push(AppRoutes.register),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Text(
              'Create account',
              style: TextStyle(
                color: AppColors.primaryRed,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
