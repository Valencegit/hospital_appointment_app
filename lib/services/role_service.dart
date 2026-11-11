import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/enums/user_role.dart';

class RoleService {
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  RoleService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<UserRole> currentRole() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to resolve the role.');
    }

    var token = await user.getIdTokenResult();
    var role = _roleFromClaims(token.claims);
    if (role != null) return role;

    try {
      await _functions.httpsCallable('ensurePatientRole').call<void>();
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'failed-precondition') {
        return UserRole.pending;
      }
      rethrow;
    }
    token = await user.getIdTokenResult(true);
    role = _roleFromClaims(token.claims);
    if (role == null) {
      throw StateError(
        'This account has no assigned hospital role. Contact an administrator.',
      );
    }
    return role;
  }

  UserRole? _roleFromClaims(Map<String, dynamic>? claims) {
    final value = claims?['role'];
    if (value is! String) return null;

    switch (value) {
      case 'patient':
        return UserRole.patient;
      case 'receptionist':
        return UserRole.receptionist;
      case 'doctor':
        return UserRole.doctor;
      case 'scheduling_officer':
        return UserRole.schedulingOfficer;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}
