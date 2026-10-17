import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/permissions/app_permissions.dart';
import 'package:nescom/models/user.dart';

User _user(UserRole role) =>
    User(id: 'u', fullName: 'Test User', email: 't@example.com', role: role);

void main() {
  group('AppPermissions', () {
    test('a null user grants nothing', () {
      final permissions = AppPermissions.forUser(null);
      expect(permissions.canManageRoster, isFalse);
      expect(permissions.canEnterScore, isFalse);
      expect(permissions.canManageLeague, isFalse);
    });

    test('an unrecognised role fails closed', () {
      final user = User(
        id: 'u',
        fullName: 'Mystery',
        email: 'm@example.com',
        role: UserRole.fromWire('wizard'),
      );
      expect(user.role, UserRole.unknown);
      final permissions = AppPermissions.forUser(user);
      expect(permissions.canManageRoster, isFalse);
      expect(permissions.canEnterScore, isFalse);
      expect(permissions.canManageStore, isFalse);
    });

    test('a club manager may manage a roster but not the league', () {
      final permissions = AppPermissions.forUser(_user(UserRole.clubManager));
      expect(permissions.canManageRoster, isTrue);
      expect(permissions.canEnterScore, isTrue);
      expect(permissions.canManageLeague, isFalse);
    });

    test('a viewer may do nothing privileged', () {
      final permissions = AppPermissions.forUser(_user(UserRole.viewer));
      expect(permissions.canManageRoster, isFalse);
      expect(permissions.canEnterScore, isFalse);
      expect(permissions.canManageLeague, isFalse);
      expect(permissions.canViewSyncStatus, isFalse);
    });

    test('a super admin may do everything', () {
      final permissions = AppPermissions.forUser(_user(UserRole.superAdmin));
      expect(permissions.canManageLeague, isTrue);
      expect(permissions.canManageRoster, isTrue);
      expect(permissions.canEnterScore, isTrue);
      expect(permissions.canManageStore, isTrue);
      expect(permissions.canViewSyncStatus, isTrue);
    });
  });

  group('UserRole parsing', () {
    test('round-trips known roles', () {
      for (final role in UserRole.values) {
        if (role == UserRole.unknown) continue;
        expect(UserRole.fromWire(role.wire), role);
      }
    });

    test('non-string values are unknown', () {
      expect(UserRole.fromWire(null), UserRole.unknown);
      expect(UserRole.fromWire(42), UserRole.unknown);
    });
  });
}
