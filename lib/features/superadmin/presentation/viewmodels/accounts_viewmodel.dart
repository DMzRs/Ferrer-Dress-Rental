import 'package:flutter/foundation.dart';

import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/audit/domain/audit_logger.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/rentals/domain/repositories/rental_repository.dart';

/// Superadmin account management: user directory, fresh admin
/// registration, and demotions. Promoting a customer to admin is refused:
/// admin accounts must be created fresh. Every mutation is audit-logged.
class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel(
      {required this._auth, required this._audit, this._rentals});

  final AuthRepository _auth;
  final AuditLogger _audit;
  final RentalRepository? _rentals;

  bool _busy = false;
  String? _error;

  bool get busy => _busy;
  String? get error => _error;

  Stream<List<AppUser>> get usersStream => _auth.watchUsers();

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  Future<bool> createAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _error = null;
    _setBusy(true);
    final result = await _auth.createAdmin(
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      password: password,
    );
    _setBusy(false);
    if (result is Success<AppUser>) {
      await _audit.log(
        'account.created',
        targetType: 'user',
        targetId: result.data.uid,
        meta: {'email': result.data.email, 'role': 'admin'},
      );
      return true;
    }
    _error =
        result.failure?.message ?? 'Something went wrong. Please try again.';
    notifyListeners();
    return false;
  }

  /// Outstanding dues on an account: (rental count, peso total) over
  /// pending/active/overdue rentals. Null when no rental source is wired.
  Future<({int count, double total})?> pendingDues(String uid) async {
    final rentals = _rentals;
    if (rentals == null) return null;
    final list = await rentals.userRentalsStream(uid).first;
    final open = list.where(
        (r) => r.isPending || r.status == 'active' || r.isOverdue);
    if (open.isEmpty) return (count: 0, total: 0.0);
    return (
      count: open.length,
      total: open.fold<double>(0, (sum, r) => sum + r.total),
    );
  }

  Future<bool> changeRole(AppUser user, UserRole role) async {
    if (user.role == role) return true;
    // Fresh accounts only: a customer can never be promoted in place.
    if (user.role == UserRole.customer && role == UserRole.admin) {
      _error = 'Admin accounts must be created fresh via Register Admin.';
      notifyListeners();
      return false;
    }
    _error = null;
    _setBusy(true);
    final result = await _auth.updateUserRole(uid: user.uid, role: role);
    _setBusy(false);
    if (result is Success<AppUser>) {
      await _audit.log(
        'account.role_changed',
        targetType: 'user',
        targetId: user.uid,
        meta: {
          'email': user.email,
          'from': user.role.name,
          'to': role.name,
        },
      );
      return true;
    }
    _error =
        result.failure?.message ?? 'Something went wrong. Please try again.';
    notifyListeners();
    return false;
  }
}
