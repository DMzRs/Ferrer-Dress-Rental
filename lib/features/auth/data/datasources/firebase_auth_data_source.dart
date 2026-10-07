import 'dart:async';
import 'package:ferrer_rental_shop/core/services/app_firestore.dart';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:ferrer_rental_shop/firebase_options.dart';

import 'package:ferrer_rental_shop/core/constants/firestore_collections.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/data/models/app_user_model.dart';
import 'auth_data_source.dart';

/// Profile write for email-link sign-up. Always fills in whatever identity
/// the link flow proved (name/phone/email) but only assigns `role` when the
/// doc is being created, so a backfilled stub gains its name without ever
/// clobbering an existing role (e.g. admin).
Map<String, dynamic> buildLinkSignupWrite({
  required bool exists,
  required String email,
  required String fullName,
  required String phone,
}) {
  return {
    'email': email,
    if (fullName.isNotEmpty) 'fullName': fullName,
    if (phone.isNotEmpty) 'phone': phone,
    if (!exists) ...{
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    },
  };
}

class FirebaseAuthDataSource implements AuthDataSource {  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => AppFirestore.instance;
  final AppLinks _appLinks = AppLinks();

  /// Must match the authorized domain + app-link host configured for the
  /// Firebase project (see README / console checklist).
  static const String _linkHost = 'ferrer-rental-shop.firebaseapp.com';

  /// Google sign-in allowlist: matching emails keep the admin role on first
  /// Google sign-in; everyone else becomes a customer.
  static const Set<String> _googleAdminEmails = {'admin@ferrer.ph'};

  /// Google credential kept when sign-in hits a password-account collision,
  /// so [linkGoogleAccount] can attach it after one password sign-in.
  AuthCredential? _pendingGoogleCredential;

  /// Web OAuth client ID (google-services.json, client_type 3). google_sign_in
  /// v7 requires it at initialize() time on Android. Public identifier, not
  /// a secret.
  static const String _googleServerClientId =
      '1088977668935-u0dug2pmbni4hu6h3sg3krsjed5khiev.apps.googleusercontent.com';

  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }

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
  Future<AppUser> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      // v7 surfaces setup problems (unregistered SHA-1, OAuth consent) as
      // `canceled` — log the raw code so logcat shows the real cause.
      debugPrint('GOOGLEDBG code=${e.code} description=${e.description}');
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google sign-in failed. Please try again.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Google sign-in failed. Please try again.');
      }
      return await _resolveGoogleUser(firebaseUser);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final pending = e.credential;
        if (pending != null) _pendingGoogleCredential = pending;
        throw GoogleLinkRequiredException((e.email ?? '').trim());
      }
      rethrow;
    }
  }

  /// Profile write for a Google sign-in. Keeps an existing doc's role (e.g.
  /// admin) and name; only brand-new docs get a role (admin allowlist,
  /// otherwise customer) plus the Google profile name.
  Future<AppUser> _resolveGoogleUser(User firebaseUser) async {
    final ref =
        _db.collection(FirestoreCollections.users).doc(firebaseUser.uid);
    final doc = await ref.get();
    final email = firebaseUser.email ?? '';
    final displayName = (firebaseUser.displayName ?? '').trim();
    if (!doc.exists) {
      final role = _googleAdminEmails.contains(email.trim().toLowerCase())
          ? 'admin'
          : 'customer';
      await ref.set({
        'email': email,
        'phone': firebaseUser.phoneNumber ?? '',
        if (displayName.isNotEmpty) 'fullName': displayName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else if (displayName.isNotEmpty &&
        (doc.data()?['fullName'] ?? '').toString().trim().isEmpty) {
      await ref.set({'fullName': displayName}, SetOptions(merge: true));
    }
    final user = await _resolveUser(firebaseUser);
    if (user == null) throw Exception('Google sign-in failed. Please try again.');
    return user;
  }

  @override
  Future<AppUser> linkGoogleAccount({
    required String email,
    required String password,
  }) async {
    final pending = _pendingGoogleCredential;
    if (pending == null) {
      throw Exception('Google sign-in expired. Please try again.');
    }
    final normalizedEmail = email.trim();
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) throw Exception('Sign-in failed. Please try again.');
    try {
      await firebaseUser.linkWithCredential(pending);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked' &&
          e.code != 'credential-already-in-use') {
        rethrow;
      }
      // Already linked — the password sign-in stands on its own.
    }
    _pendingGoogleCredential = null;
    final user = await _resolveUser(firebaseUser);
    if (user == null) throw Exception('Account not found');
    return user;
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
    // Merge, don't gate on existence: the auth-state listener can backfill a
    // nameless stub doc before this write runs; a conditional create would
    // then skip the real profile forever.
    await ref.set(
      buildLinkSignupWrite(
        exists: doc.exists,
        email: normalizedEmail,
        fullName: name,
        phone: phoneNumber,
      ),
      SetOptions(merge: true),
    );
    final user = await _resolveUser(firebaseUser);
    if (user == null) throw Exception('Account not found');
    return user;
  }

  /// Redacted link probe: never prints the oobCode or email, only the
  /// shape Firebase needs (mode present, code present + length). If the OS
  /// or link handler strips query parameters, oobLen comes back 0 and the
  /// backend answers invalid-action-code.
  void _logLink(String tag, String link) {
    final uri = Uri.tryParse(link);
    final oob = uri?.queryParameters['oobCode'] ?? '';
    debugPrint(
      'LINKDBG $tag mode=${uri?.queryParameters['mode']} '
      'oobLen=${oob.length} '
      'apiKey=${(uri?.queryParameters['apiKey'] ?? '').isNotEmpty} '
      'len=${link.length}',
    );
  }

  @override
  Stream<String> get emailLinkStream async* {
    final initial = await _appLinks.getInitialLink();
    if (initial != null &&
        _auth.isSignInWithEmailLink(initial.toString())) {
      _logLink('initial', initial.toString());
      yield initial.toString();
    }
    await for (final uri in _appLinks.uriLinkStream) {
      final link = uri.toString();
      if (_auth.isSignInWithEmailLink(link)) {
        _logLink('stream', link);
        yield link;
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Otherwise the next Google tap silently reuses the same account
    // without showing the chooser.
    try {
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Mock mode / already signed out — Firebase sign-out stands.
    }
  }

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
  Stream<int> usersCountStream() async* {
    // Aggregate count query instead of streaming the whole collection:
    // one tiny read per refresh rather than N document reads on every
    // user change. Failures are skipped so a blip never zeroes the tile.
    final first = await _usersCountOrNull();
    if (first != null) yield first;
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      final count = await _usersCountOrNull();
      if (count != null) yield count;
    }
  }

  Future<int?> _usersCountOrNull() async {
    try {
      final aggregate =
          await _db.collection(FirestoreCollections.users).count().get();
      return aggregate.count;
    } on Object {
      return null;
    }
  }

  @override
  Stream<List<AppUser>> watchUsers() {
    return _db
        .collection(FirestoreCollections.users)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AppUserModel.fromMap(d.id, d.data())).toList());
  }

  /// Superadmin-only (enforced by rules): creates an admin account through a
  /// secondary Firebase app so the superadmin's own session is untouched.
  @override
  Future<AppUser> createAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    FirebaseApp secondary;
    try {
      secondary = Firebase.app('ferrer-admin-creator');
    } catch (_) {
      secondary = await Firebase.initializeApp(
        name: 'ferrer-admin-creator',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
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
        role: UserRole.admin,
      );
      await _db
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(model.toMap());
      return model;
    } finally {
      await secondaryAuth.signOut();
    }
  }

  /// Superadmin-only (enforced by rules): changes a user's role. Refuses to
  /// demote a superadmin client-side too, so the UI fails fast.
  @override
  Future<AppUser> updateUserRole({
    required String uid,
    required UserRole role,
  }) async {
    final ref = _db.collection(FirestoreCollections.users).doc(uid);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Account not found.');
    if (doc.data()?['role'] == 'superadmin' && role != UserRole.superadmin) {
      throw Exception('A superadmin account cannot be demoted.');
    }
    if (doc.data()?['role'] == 'customer' && role == UserRole.admin) {
      throw Exception(
          'Admin accounts must be created fresh via Register Admin.');
    }
    await ref.set({
      'role': role == UserRole.superadmin
          ? 'superadmin'
          : role == UserRole.admin
              ? 'admin'
              : 'customer',
    }, SetOptions(merge: true));
    final updated = await ref.get();
    return AppUserModel.fromMap(uid, updated.data()!);
  }
}

