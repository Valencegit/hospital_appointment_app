import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Higher-level user/account operations used mainly by admin screens.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

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

  Future<void> setUserActive(String uid, {required bool active}) async {
    await _functions.httpsCallable('setUserAccountStatus').call({
      'uid': uid,
      'active': active,
    });
  }

  Future<void> updateUserRole(String uid, String role) async {
    const roles = {
      AppConstants.rolePatient,
      AppConstants.roleDoctor,
      AppConstants.roleReceptionist,
      AppConstants.roleSchedulingOfficer,
      AppConstants.roleAdmin,
    };
    if (!roles.contains(role)) {
      throw ArgumentError.value(role, 'role', 'Invalid hospital role.');
    }
    await _functions.httpsCallable('assignUserRole').call({
      'uid': uid,
      'role': role,
    });
  }
}
