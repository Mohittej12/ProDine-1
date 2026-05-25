import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pro_dine/core/constants/app_routes.dart';
import 'package:pro_dine/features/admin/pages/admin_add_food_page.dart';
import 'package:pro_dine/features/admin/pages/admin_dashboard_page.dart';
import 'package:pro_dine/features/admin/pages/admin_edit_food_page.dart';
import 'package:pro_dine/features/admin/pages/admin_food_items_page.dart';
import 'package:pro_dine/features/admin/pages/admin_menu_management_page.dart';
import 'package:pro_dine/features/admin/pages/admin_reports_page.dart';
import 'package:pro_dine/features/admin/pages/admin_upload_ticket_data_page.dart';
import 'package:pro_dine/features/admin/pages/admin_vendor_performance_page.dart';
import 'package:pro_dine/features/admin/pages/admin_vendors_page.dart';
import 'package:pro_dine/features/admin/widgets/admin_shell.dart';
import 'package:pro_dine/features/auth/pages/auth_forgot_password_page.dart';
import 'package:pro_dine/features/auth/pages/auth_login_page.dart';
import 'package:pro_dine/features/auth/pages/auth_register_page.dart';
import 'package:pro_dine/features/auth/pages/auth_verify_mobile_page.dart';
import 'package:pro_dine/features/common/pages/onboarding_page.dart';
import 'package:pro_dine/features/common/pages/splash_page.dart';
import 'package:pro_dine/features/common/pages/terms_and_disclaimer_page.dart';
import 'package:pro_dine/features/employee/pages/employee_cart_page.dart';
import 'package:pro_dine/features/employee/pages/employee_checkout_page.dart';
import 'package:pro_dine/features/employee/pages/employee_favorites_page.dart';
import 'package:pro_dine/features/employee/pages/employee_main_page.dart';
import 'package:pro_dine/features/employee/pages/employee_meal_authorization_page.dart';
import 'package:pro_dine/features/employee/data/employee_order_store.dart';
import 'package:pro_dine/features/employee/pages/employee_ticketing_page.dart';
import 'package:pro_dine/features/employee/pages/employee_mode_selection_page.dart';
import 'package:pro_dine/features/employee/pages/employee_payment_status_page.dart';
import 'package:pro_dine/features/employee/pages/employee_terms_page.dart';
import 'package:pro_dine/features/employee/pages/employee_usage_page.dart';
import 'package:pro_dine/features/employee/pages/ticketing_main_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_add_food_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_dashboard_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_edit_food_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_food_items_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_food_portions_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_orders_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_reports_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_terms_page.dart';
import 'package:pro_dine/features/vendor/pages/vendor_ticket_data_page.dart';
import 'package:pro_dine/features/vendor/widgets/vendor_shell.dart';

// ── Shared transition builder ──────────────────────────────────────────────
// Fast app-wide slide transition. Push slides in from right; pop slides out right.
CustomTransitionPage<T> _buildTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 220),
  Duration reverseDuration = const Duration(milliseconds: 180),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: false,
        child: child,
      );
    },
  );
}

// No-transition page (for splash / root redirect)
CustomTransitionPage<void> _noTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (_1, _2, _3, child) => child,
  );
}

// ── Router ─────────────────────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.root,
      redirect: (context, state) => AppRoutes.splash,
    ),
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) =>
          _noTransitionPage(child: const SplashPage(), state: state),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _buildTransitionPage(child: const OnboardingPage(), state: state),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) =>
          _buildTransitionPage(child: const AuthLoginPage(), state: state),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) =>
          _buildTransitionPage(child: const AuthRegisterPage(), state: state),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const AuthForgotPasswordPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.verifyMobile,
      pageBuilder: (context, state) {
        final mobileNumber =
            state.extra is String ? state.extra as String : null;
        return _buildTransitionPage(
          child: AuthVerifyMobilePage(mobileNumber: mobileNumber),
          state: state,
        );
      },
    ),
    // Employee
    GoRoute(
      path: AppRoutes.employeeModeSelection,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeModeSelectionPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeHome,
      pageBuilder: (context, state) => _noTransitionPage(
        child: const EmployeeMainPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeMenu,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeMainPage(initialIndex: 1),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeCart,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: EmployeeCartPage(
          selectedShopName: state.uri.queryParameters['shop'],
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeCheckout,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeCheckoutPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeePaymentStatus,
      pageBuilder: (context, state) {
        final order = state.extra is EmployeeOrderEntry
            ? state.extra as EmployeeOrderEntry
            : null;

        return _buildTransitionPage(
          child: EmployeePaymentStatusPage(order: order),
          state: state,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.employeeTicketing,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeTicketingPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeMealAuthorization,
      pageBuilder: (context, state) {
        final mealType = state.extra is String ? state.extra as String : null;
        return _buildTransitionPage(
          child: EmployeeMealAuthorizationPage(selectedMealType: mealType),
          state: state,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.employeeOrders,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeMainPage(initialIndex: 2),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeProfile,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeMainPage(initialIndex: 3),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeFavorites,
      pageBuilder: (context, state) => _buildTransitionPage(
        child: const EmployeeFavoritesPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.ticketingHome,
      pageBuilder: (context, state) => _noTransitionPage(
        child: const TicketingMainPage(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.employeeUsage,
      pageBuilder: (context, state) =>
          _buildTransitionPage(child: const EmployeeUsagePage(), state: state),
    ),
    GoRoute(
      path: AppRoutes.employeeTerms,
      pageBuilder: (context, state) =>
          _buildTransitionPage(child: const EmployeeTermsPage(), state: state),
    ),
    // Vendor Shell
    ShellRoute(
      builder: (context, state, child) =>
          VendorShell(currentRoute: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.vendorDashboard,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorDashboardPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorOrders,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorOrdersPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorFoodItems,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorFoodItemsPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorFoodPortions,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorFoodPortionsPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorAddFood,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorAddFoodPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorEditFood,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorEditFoodPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorReports,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorReportsPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorTicketData,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorTicketDataPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.vendorTerms,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const VendorTermsPage(),
            state: state,
          ),
        ),
      ],
    ),
    // Admin Shell
    ShellRoute(
      builder: (context, state, child) =>
          AdminShell(currentRoute: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.adminDashboard,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminDashboardPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminVendors,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminVendorsPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminVendorPerformance,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminVendorPerformancePage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminMenuManagement,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminMenuManagementPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminFoodItems,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminFoodItemsPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminAddFood,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminAddFoodPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminEditFood,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminEditFoodPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminUploadTicketData,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminUploadTicketDataPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminReports,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const AdminReportsPage(),
            state: state,
          ),
        ),
        GoRoute(
          path: AppRoutes.adminTerms,
          pageBuilder: (context, state) => _buildTransitionPage(
            child: const TermsAndDisclaimerPage(),
            state: state,
          ),
        ),
      ],
    ),
  ],
);
