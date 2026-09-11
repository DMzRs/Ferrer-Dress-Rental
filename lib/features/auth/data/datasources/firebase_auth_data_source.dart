import 'dart:async';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/data/models/app_user_model.dart';
import 'auth_data_source.dart';

class FirebaseAuthDataSource implements AuthDataSource {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => AppFirestore.instance;
  final AppLinks _appLinks = AppLinks();

  /// Must match the authorized domain + app-link host configured for the
  /// Firebase project (see README / console checklist).
  static const String _linkHost = 'ferrer-rental-shop.firebaseapp.com';

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().asyncMap(_resolveUser);

  Future<AppUser?> _resolveUser(User? user) async {
    if (user == null) return null;
    final ref = _db.collection(FirestoreCollections.users).doc(user.uid);
    final doc = await ref.get();
    if (doc.exists) {
      return AppUserModel.fromMap(user.uid, doc.data()!);
    }
    // Profile doc is missing (e.g. sign-up created the Auth account but the
    // Firestore write failed, or the user was created in the console).
    // Backfill it so role and profile data have a source of truth. The write
    // is a MERGE and omits fullName when Auth has no display name, so it can
    // never clobber the real profile a concurrent sign-up is writing.
    final displayName = user.displayName ?? '';
    final model = AppUserModel(
      uid: user.uid,
      fullName: displayName,
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      role: UserRole.customer,
    );
    try {
      await ref.set({
        'email': model.email,
        'phone': model.phone,
        'role': 'customer',
        if (displayName.trim().isNotEmpty) 'fullName': displayName.trim(),
      }, SetOptions(merge: true));
    } on Object {
      // A failed backfill must not break sign-in; the next auth event retries.
    }
    return model;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = await _resolveUser(credential.user);
    if (user == null) throw Exception('Account not found');
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    await credential.user!.updateDisplayName(fullName.trim());
    final model = AppUserModel(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: UserRole.customer,
    );
    await _db.collection(FirestoreCollections.users).doc(uid).set(model.toMap());
    return model;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> sendSignInLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://$_linkHost/__/auth/handler',
      handleCodeInApp: true,
      androidPackageName: 'com.example.ferrer_rental_shop',
      androidInstallApp: false,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.example.ferrerRentalShop',
    );
    await _auth.sendSignInLinkToEmail(
      email: email.trim(),
      actionCodeSettings: actionCodeSettings,
    );
  }

  @override
  Future<AppUser> signInWithEmailLink({
    required String email,
    required String link,
    String? fullName,
    String? phone,
    String? password,
  }) async {
    final normalizedEmail = email.trim();
    final credential = await _auth.signInWithEmailLink(
      email: normalizedEmail,
      emailLink: link,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) throw Exception('Sign-in failed. Try the link again.');
    // Attach the password login so the account also works with
    // email + password afterwards. Best-effort: the link sign-in above
    // already proves email ownership.
    final pwd = password ?? '';
    if (pwd.length >= 6) {
      try {
        await firebaseUser.linkWithCredential(
          EmailAuthProvider.credential(email: normalizedEmail, password: pwd),
        );
      } on Object {
        // Already linked or provider conflict — link sign-in stands on its own.
      }
    }
    final name = fullName?.trim() ?? '';
    final phoneNumber = phone?.trim() ?? '';
    if (name.isNotEmpty && (firebaseUser.displayName ?? '').isEmpty) {
      await firebaseUser.updateDisplayName(name);
    }
    final ref = _db.collection(FirestoreCollections.users).doc(firebaseUser.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set(AppUserModel(
        uid: firebaseUser.uid,
        fullName: name,
        email: normalizedEmail,
        phone: phoneNumber,
        role: UserRole.customer,
      ).toMap());
    }
    final user = await _resolveUser(firebaseUser);
    if (user == null) throw Exception('Account not found');
    return user;
  }

  @override
  Stream<String> get emailLinkStream async* {
    final initial = await _appLinks.getInitialLink();
    if (initial != null &&
        _auth.isSignInWithEmailLink(initial.toString())) {
      yield initial.toString();
    }
    await for (final uri in _appLinks.uriLinkStream) {
      final link = uri.toString();
      if (_auth.isSignInWithEmailLink(link)) yield link;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    final updates = <String, dynamic>{
      if (fullName != null) 'fullName': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
      if (address != null) 'address': address.trim(),
      'savedPlaces': ?savedPlaces,
    };
    if (updates.isEmpty) return;

    if (fullName != null) {
      await _auth.currentUser!.updateDisplayName(fullName.trim());
    }
    await _db.collection(FirestoreCollections.users).doc(uid).update(updates);
  }

  @override
  Stream<int> usersCountStream() => _db
      .collection(FirestoreCollections.users)
      .snapshots()
      .map((s) => s.docs.length);
}

