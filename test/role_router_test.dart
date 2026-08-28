import 'package:addis_bites/models/session.dart';
import 'package:addis_bites/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('role routing redirects are role-aware', (tester) async {
    const cases = {
      UserRole.customer: '/app',
      UserRole.merchant: '/dash/merchant',
      UserRole.driver: '/dash/driver',
      UserRole.admin: '/admin',
      UserRole.ceo: '/dash/ceo',
      UserRole.support: '/dash/support',
      UserRole.finance: '/dash/finance',
    };

    for (final entry in cases.entries) {
      final session = Session(
        token: 't',
        profile: Profile(id: 'p', phone: '+251911000001', name: 'N', role: entry.key),
      );
      expect(AppRouter.homeFor(session), entry.value, reason: entry.key.name);
    }
  });

    test('foot vehicle driver routes to carrier', () {
      final session = const Session(
        token: 't',
        profile: Profile(id: 'p', phone: '+251911000001', name: 'N', role: UserRole.driver, vehicle: 'foot'),
      );
      expect(AppRouter.homeFor(session), '/carrier');
    });

    test('no session routes to join', () {
    expect(AppRouter.homeFor(null), '/join');
  });
}