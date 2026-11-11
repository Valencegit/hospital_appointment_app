import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/enums/user_role.dart';

/// Resolves the authenticated user's role using this priority chain:
///
///  1. Firebase Auth ID token custom claim (`role`)  — most trusted.
///  2. Firestore `users/{uid}.role` field            — written on registration.
///  3. `UserRole.patient` default                    — safe fallback, never crashes.
///
/// The Cloud Function path is attempted only when the token has no claim AND
/// the function is reachable. If not yet deployed or offline, falls through
/// to Firestore silently.
class RoleService {
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _db;

  RoleService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance,
        _db = db ?? FirebaseFirestore.instance;

  /// Returns the authoritative role for the currently signed-in user.
  /// Never throws — always resolves to a valid [UserRole].
  Future<UserRole> currentRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[RoleService] No signed-in user — defaulting to pending.');
      return UserRole.pending;
    }

    // ── 1. Existing token claim (no network round-trip) ───────────────────
    try {
      final token = await user.getIdTokenResult();
      final claimed = _roleFromClaims(token.claims);
      if (claimed != null) {
        debugPrint('[RoleService] Role from token claim: ${claimed.toValue()}');
        return claimed;
      }
    } catch (e) {
      debugPrint('[RoleService] Could not read token claims: $e');
    }

    // ── 2. Try Cloud Function to stamp claim for new patient accounts ─────
    try {
      await _functions.httpsCallable('ensurePatientRole').call<void>();
      final refreshed = await user.getIdTokenResult(true);
      final claimed = _roleFromClaims(refreshed.claims);
      if (claimed != null) {
        debugPrint(
            '[RoleService] Role from Cloud Function: ${claimed.toValue()}');
        return claimed;
      }
    } on FirebaseFunctionsException catch (e) {
      // not-found  = function not deployed yet  → fall through to Firestore
      // permission-denied = staff/admin account → fall through to Firestore
      debugPrint(
          '[RoleService] ensurePatientRole skipped (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('[RoleService] ensurePatientRole error (non-fatal): $e');
    }

    // ── 3. Firestore fallback ─────────────────────────────────────────────
    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final roleStr = doc.data()?['role'] as String?;
        final firestoreRole = UserRole.fromString(roleStr);
        debugPrint(
            '[RoleService] Role from Firestore: ${firestoreRole.toValue()}');
        return firestoreRole;
      }
    } catch (e) {
      debugPrint('[RoleService] Firestore role lookup failed: $e');
    }

    // ── 4. Safe default ───────────────────────────────────────────────────
    debugPrint('[RoleService] All lookups failed — defaulting to patient.');
    return UserRole.patient;
  }

  UserRole? _roleFromClaims(Map<String, dynamic>? claims) {
    final value = claims?['role'];
    if (value is! String) return null;

    final parsed = UserRole.fromString(value);
    if (parsed == UserRole.pending &&
        value.trim().toLowerCase() != 'pending') {
      return null;
    }
    return parsed;
  }
}
