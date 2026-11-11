import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Higher-level user/account operations used mainly by admin screens.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<UserModel>> usersStream() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('email')
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  Stream<List<UserModel>> doctorsStream() {
    return _db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.roleDoctor)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(UserModel.fromFirestore)
            .where((user) => user.isActive)
            .toList());
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  // ── Activate / deactivate ──────────────────────────────────────────────────

  Future<void> setUserActive(String uid, {required bool active}) async {
    await _functions.httpsCallable('setUserAccountStatus').call({
      'uid': uid,
      'active': active,
    });
  }

  // ── Role assignment ────────────────────────────────────────────────────────

  Future<void> updateUserRole(String uid, String role) async {
    const validRoles = {
      AppConstants.rolePatient,
      AppConstants.roleDoctor,
      AppConstants.roleReceptionist,
      AppConstants.roleSchedulingOfficer,
      AppConstants.roleAdmin,
    };
    if (!validRoles.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Invalid hospital role.');
    }

    await _functions.httpsCallable('assignUserRole').call({
      'uid': uid,
      'role': role,
    });
  }

  Future<void> createStaffAccount({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String employeeId,
    required String departmentId,
    required String role,
    String? specialization,
  }) async {
    const staffRoles = {
      AppConstants.roleDoctor,
      AppConstants.roleReceptionist,
      AppConstants.roleSchedulingOfficer,
    };
    if (!staffRoles.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Invalid staff role.');
    }

    await _functions.httpsCallable('createStaffUser').call({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'employeeId': employeeId.trim(),
      'departmentId': departmentId,
      'role': role,
      if (specialization != null && specialization.trim().isNotEmpty)
        'specialization': specialization.trim(),
    });
  }
}
