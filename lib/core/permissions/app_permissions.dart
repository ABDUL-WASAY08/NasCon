import 'package:flutter/foundation.dart';

import '../../models/user.dart';

/// Central capability check.
///
/// This is the **only** place role → capability mapping lives. It fails closed:
/// a `null` user or an unrecognised role grants nothing.
///
/// Hiding a control is *not* authorization — the backend must independently
/// enforce every privileged operation.
@immutable
class AppPermissions {
  const AppPermissions._({
    required this.canManageLeague,
    required this.canManageRoster,
    required this.canEnterScore,
    required this.canManageStore,
    required this.canViewSyncStatus,
  });

  final bool canManageLeague;
  final bool canManageRoster;
  final bool canEnterScore;
  final bool canManageStore;
  final bool canViewSyncStatus;

  static const AppPermissions none = AppPermissions._(
    canManageLeague: false,
    canManageRoster: false,
    canEnterScore: false,
    canManageStore: false,
    canViewSyncStatus: false,
  );

  factory AppPermissions.forUser(User? user) {
    final role = user?.role;
    if (role == null) return none;

    return switch (role) {
      UserRole.superAdmin => const AppPermissions._(
        canManageLeague: true,
        canManageRoster: true,
        canEnterScore: true,
        canManageStore: true,
        canViewSyncStatus: true,
      ),
      UserRole.leagueOrganizer => const AppPermissions._(
        canManageLeague: true,
        canManageRoster: true,
        canEnterScore: true,
        canManageStore: true,
        canViewSyncStatus: true,
      ),
      UserRole.clubManager => const AppPermissions._(
        canManageLeague: false,
        canManageRoster: true,
        canEnterScore: true,
        canManageStore: false,
        canViewSyncStatus: true,
      ),
      UserRole.player => const AppPermissions._(
        canManageLeague: false,
        canManageRoster: false,
        canEnterScore: false,
        canManageStore: false,
        canViewSyncStatus: true,
      ),
      UserRole.viewer => const AppPermissions._(
        canManageLeague: false,
        canManageRoster: false,
        canEnterScore: false,
        canManageStore: false,
        canViewSyncStatus: false,
      ),
      // Fail closed for anything the backend sends that we do not recognise.
      UserRole.unknown => none,
    };
  }
}
