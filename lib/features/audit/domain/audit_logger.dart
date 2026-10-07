import 'dart:async';

import 'package:ferrer_rental_shop/features/audit/domain/entities/audit_log_entry.dart';
import 'package:ferrer_rental_shop/features/audit/domain/repositories/audit_repository.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';

/// Best-effort audit writer. Tracks the signed-in actor from the auth stream
/// so viewmodels log with one call; pass [actor] explicitly when the actor
/// isn't the signed-in user (e.g. recording a just-created account).
/// Failures are swallowed — logging never breaks the action it records.
class AuditLogger {
  AuditLogger({required AuthRepository auth, required this._logs}) {
    _sub = auth.authStateChanges.listen((user) => _actor = user);
  }

  final AuditRepository _logs;
  StreamSubscription<AppUser?>? _sub;
  AppUser? _actor;

  Future<void> log(
    String action, {
    AppUser? actor,
    String targetType = '',
    String targetId = '',
    Map<String, String> meta = const {},
  }) async {
    final a = actor ?? _actor;
    if (a == null) return;
    try {
      await _logs.log(AuditLogEntry(
        id: '',
        actorUid: a.uid,
        actorEmail: a.email,
        action: action,
        targetType: targetType,
        targetId: targetId,
        at: DateTime.now(),
        meta: meta,
      ));
    } catch (_) {
      // Best-effort by design.
    }
  }

  void dispose() => _sub?.cancel();
}
