import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/customer/cart_screen.dart';
import '../features/customer/checkout_screen.dart';
import '../features/customer/orders_screen.dart';
import '../features/customer/restaurant_screen.dart';
import '../features/customer/tracking_screen.dart';
import '../features/dash/admin_shell.dart';
import '../features/dash/carrier_screen.dart';
import '../features/dash/ceo_shell.dart';
import '../features/dash/driver_shell.dart';
import '../features/dash/field_agent_screen.dart';
import '../features/dash/merchant_shell.dart';
import '../features/dash/support_shell.dart';
import '../features/dash/finance_shell.dart';
import '../features/join_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell.dart' show CustomerShell;
import '../features/sponsor_pay_screen.dart';
import '../features/splash.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';

/// Role-guarded router. Guards read the stored session token + profile:
///  - no token   -> /join
///  - customer   -> /app (CustomerShell)
///  - merchant   -> /dash/merchant
///  - driver     -> /dash/driver
///  - admin      -> /admin
///  - ceo        -> /dash/ceo
class AppRouter {
  AppRouter._();

  static GoRouter build(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: _RefreshListenable(ref),
      redirect: (context, state) {
        final session = ref.read(sessionProvider);
        final logged = session != null;
        final path = state.uri.path;
        final goingToJoin = path == '/join';

        if (!logged) {
          return goingToJoin ? null : '/join';
        }
        if (goingToJoin || path == '/') {
          return _homeFor(session);
        }
        // Telegram Mini App deep links (§9):
        //   ?startapp=restaurant_<id>  → open a merchant menu directly
        //   ?startapp=cart_<token>     → join a shared group cart
        if (session.profile.role == UserRole.customer && path == '/app') {
          final startapp = state.uri.queryParameters['startapp'] ?? state.uri.queryParameters['startApp'];
          if (startapp != null) {
            if (startapp.startsWith('restaurant_')) {
              final id = startapp.substring('restaurant_'.length);
              if (id.isNotEmpty) return '/restaurant/$id';
            } else if (startapp.startsWith('cart_')) {
              return '/app'; // group-cart join handled in the shell when live
            }
          }
        }
        // Customer routes are only for the customer role.
        if (session.profile.role != UserRole.customer && path.startsWith('/app')) {
          return _homeFor(session);
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(path: '/join', builder: (context, state) => const JoinScreen()),
        // ---- Customer app ----
        GoRoute(path: '/app', builder: (context, state) => const CustomerShell()),
        GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
        GoRoute(
          path: '/restaurant/:id',
          builder: (context, state) => RestaurantScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
        GoRoute(
          path: '/order/:id',
          builder: (context, state) => OrderTrackingScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
        // ---- Role dashboards ----
        GoRoute(path: '/dash/merchant', builder: (context, state) => const MerchantShell()),
        GoRoute(path: '/dash/driver', builder: (context, state) => const DriverShell()),
        GoRoute(path: '/carrier', builder: (context, state) => const CarrierScreen()),
        GoRoute(path: '/carrier/onboard', builder: (context, state) => const CarrierScreen(initialStep: 1)),
        GoRoute(path: '/carrier/earnings', builder: (context, state) => const CarrierScreen(initialStep: 3)),
        GoRoute(path: '/field', builder: (context, state) => const FieldAgentScreen()),
        GoRoute(path: '/admin', builder: (context, state) => const AdminShell()),
        GoRoute(path: '/dash/ceo', builder: (context, state) => const CeoShell()),
        GoRoute(path: '/dash/support', builder: (context, state) => const SupportShell()),
        GoRoute(path: '/dash/finance', builder: (context, state) => const FinanceShell()),
        // §3.5 diaspora sponsor-pay: /g/<token> deep link
        GoRoute(path: '/g/:token', builder: (context, state) => SponsorPayScreen(token: state.pathParameters['token'] ?? '')),
      ],
    );
  }

  /// Public so tests can assert role-gated redirect targets.
  static String homeFor(Session? session) {
    if (session == null) return '/join';
    switch (session.profile.role) {
      case UserRole.customer:
        return '/app';
      case UserRole.merchant:
        return '/dash/merchant';
      case UserRole.driver:
        if (session.profile.vehicle == 'foot') return '/carrier';
        return '/dash/driver';
      case UserRole.admin:
        return '/admin';
      case UserRole.ceo:
        return '/dash/ceo';
      case UserRole.support:
        return '/dash/support';
      case UserRole.finance:
        return '/dash/finance';
    }
  }

  static String _homeFor(Session? session) => homeFor(session);
}

/// Notifies the router when the session changes so redirects re-evaluate.
class _RefreshListenable extends ChangeNotifier {
  final WidgetRef _ref;
  _RefreshListenable(this._ref) {
    _ref.listen(sessionProvider, (prev, next) => notifyListeners());
  }
}