import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Higher-level user/account operations used mainly by admin screens.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<UserModel>> usersStream() {
    return _db
        .collection(AppConstants.usersCollection)
        .orderBy('email')
        .snapshots()
        .map((s) => s.docs.map(UserModel.fromFirestore).toList());
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Future<void> setUserActive(String uid, {required bool active}) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'is_active': active,
      'isActive': active,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRole(String uid, String role) async {
    assert(
        [
          AppConstants.rolePatient,
          AppConstants.roleStaff,
          AppConstants.roleDoctor,
          AppConstants.roleReceptionist,
          AppConstants.roleAdmin,
        ].contains(role),
        'Invalid role: $role');
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'role': role,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
