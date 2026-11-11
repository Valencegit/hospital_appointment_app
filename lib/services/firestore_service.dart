import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/user_role.dart';
import '../models/admin_model.dart';
import '../models/department_model.dart';
import '../models/notification_model.dart';
import '../models/patient_model.dart';
import '../models/slot_model.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';

/// Database service managing all Firestore interactions for users,
/// patients, medical staff, and administrators.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseFirestore get db => _firestore;

  // Collection References
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _patientsCol =>
      _firestore.collection(AppConstants.patientsCollection);

  CollectionReference<Map<String, dynamic>> get _staffCol =>
      _firestore.collection(AppConstants.staffCollection);

  CollectionReference<Map<String, dynamic>> get _adminsCol =>
      _firestore.collection(AppConstants.colAdmins);

  CollectionReference<Map<String, dynamic>> get _departmentsCol =>
      _firestore.collection(AppConstants.departmentsCollection);

  CollectionReference<Map<String, dynamic>> get _slotsCol =>
      _firestore.collection(AppConstants.slotsCollection);

  // ---------------------------------------------------------------------------
  // Base User Operations
  // ---------------------------------------------------------------------------

  Future<void> createUser(UserModel user) async {
    try {
      await _usersCol.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] createUser error: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreService] getUser error: $e');
      return null;
    }
  }

  Stream<UserModel?> streamUser(String uid) {
    return _usersCol.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromFirestore(snapshot);
    });
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final updatedData = user.copyWith(updatedAt: DateTime.now()).toMap();
      await _usersCol.doc(user.uid).update(updatedData);
    } catch (e) {
      debugPrint('[FirestoreService] updateUser error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Patient Operations
  // ---------------------------------------------------------------------------

  Future<void> createPatientProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? emergencyContact,
    String? address,
  }) async {
    try {
      final parts = fullName.trim().split(' ');
      final first = parts.isNotEmpty ? parts.first : '';
      final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final patient = PatientModel(
        uid: uid,
        firstName: first,
        lastName: last,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        bloodGroup: bloodGroup,
        emergencyContactPhone: emergencyContact,
        address: address,
        createdAt: DateTime.now(),
      );
      await _patientsCol.doc(uid).set(patient.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] createPatientProfile error: $e');
      rethrow;
    }
  }

  Future<PatientModel?> getPatient(String uid) async {
    try {
      final doc = await _patientsCol.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return PatientModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreService] getPatient error: $e');
      return null;
    }
  }

  Future<PatientModel?> getPatientProfile(String uid) => getPatient(uid);

  Future<void> savePatient(PatientModel patient) async {
    await _patientsCol
        .doc(patient.uid)
        .set(patient.toMap(), SetOptions(merge: true));
  }

  Future<void> updatePatientProfile(PatientModel patient) =>
      savePatient(patient);

  // ---------------------------------------------------------------------------
  // Staff Operations
  // ---------------------------------------------------------------------------

  Future<void> createStaffProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required UserRole role,
    String departmentId = 'dept_general',
    String departmentName = 'General Medicine',
    String specialization = 'General Physician',
    String licenseNumber = '',
    double consultationFee = 0.0,
    List<String> availableDays = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday'
    ],
  }) async {
    try {
      final parts = fullName.trim().split(' ');
      final first = parts.isNotEmpty ? parts.first : '';
      final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      final staff = StaffModel(
        uid: uid,
        firstName: first,
        lastName: last,
        email: email,
        phoneNumber: phoneNumber,
        staffRole: role.toValue(),
        departmentId: departmentId,
        departmentName: departmentName,
        specialization: specialization,
        licenseNumber: licenseNumber,
        consultationFee: consultationFee,
        availableDays: availableDays,
        isAvailable: true,
        createdAt: DateTime.now(),
      );
      await _staffCol.doc(uid).set(staff.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] createStaffProfile error: $e');
      rethrow;
    }
  }

  Future<StaffModel?> getStaff(String uid) async {
    try {
      final doc = await _staffCol.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return StaffModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreService] getStaff error: $e');
      return null;
    }
  }

  Future<StaffModel?> getStaffProfile(String uid) => getStaff(uid);

  Future<void> saveStaff(StaffModel staff) async {
    await _staffCol.doc(staff.uid).set(staff.toMap(), SetOptions(merge: true));
  }

  Future<void> updateStaffProfile(StaffModel staff) => saveStaff(staff);

  // ---------------------------------------------------------------------------
  // Administrator Operations
  // ---------------------------------------------------------------------------

  Future<void> createAdminProfile({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    String department = 'Hospital Administration',
    List<String>? permissions,
  }) async {
    try {
      final admin = AdminModel(
        uid: uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        department: department,
        permissions: permissions ??
            const [
              'manage_users',
              'manage_staff',
              'manage_departments',
              'manage_slots',
              'view_analytics',
              'system_configuration',
            ],
        createdAt: DateTime.now(),
      );
      await _adminsCol.doc(uid).set(admin.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] createAdminProfile error: $e');
      rethrow;
    }
  }

  Future<AdminModel?> getAdminProfile(String uid) async {
    try {
      final doc = await _adminsCol.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AdminModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[FirestoreService] getAdminProfile error: $e');
      return null;
    }
  }

  Future<void> updateAdminProfile(AdminModel admin) async {
    await _adminsCol.doc(admin.uid).update(admin.toMap());
  }

  // ---------------------------------------------------------------------------
  // Department & Slot Operations (Preserved for compatibility)
  // ---------------------------------------------------------------------------

  Stream<List<DepartmentModel>> activeDepartmentsStream() {
    return _departmentsCol
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(DepartmentModel.fromFirestore).toList());
  }

  Stream<List<DepartmentModel>> departmentsStream() {
    return _departmentsCol
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(DepartmentModel.fromFirestore).toList());
  }

  Future<List<DepartmentModel>> getAllDepartments() async {
    final snap = await _departmentsCol.orderBy('name').get();
    return snap.docs.map(DepartmentModel.fromFirestore).toList();
  }

  Future<void> saveDepartment(DepartmentModel dept) async {
    final ref =
        dept.id.isEmpty ? _departmentsCol.doc() : _departmentsCol.doc(dept.id);
    final data = dept.toFirestore();
    data['department_id'] = ref.id;
    await ref.set(data, SetOptions(merge: true));
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _departmentsCol.doc(id).update(data);
  }

  Stream<List<SlotModel>> slotsForDepartment(
      String departmentId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _slotsCol
        .where('departmentId', isEqualTo: departmentId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            isLessThan: Timestamp.fromDate(end))
        .where('isActive', isEqualTo: true)
        .orderBy('date')
        .orderBy('startTime')
        .snapshots()
        .map((s) => s.docs.map(SlotModel.fromFirestore).toList());
  }

  Stream<List<SlotModel>> slotsForDoctor(String doctorId) {
    return _slotsCol.where('doctorId', isEqualTo: doctorId).snapshots().map(
        (s) => s.docs
            .map(SlotModel.fromFirestore)
            .where((slot) => slot.isActive)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date)));
  }

  Future<List<SlotModel>> getAllSlots({String? departmentId}) async {
    Query<Map<String, dynamic>> q = _slotsCol.orderBy('date');
    if (departmentId != null) {
      q = q.where('departmentId', isEqualTo: departmentId);
    }
    final snap = await q.get();
    return snap.docs.map(SlotModel.fromFirestore).toList();
  }

  Future<void> saveSlot(SlotModel slot) async {
    final ref = slot.id.isEmpty ? _slotsCol.doc() : _slotsCol.doc(slot.id);
    await ref.set(slot.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateSlot(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _slotsCol.doc(id).update(data);
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(NotificationModel.fromFirestore).toList());
  }

  Future<void> markNotificationRead(String id) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(id)
        .update({'isRead': true});
  }

  // ---------------------------------------------------------------------------
  // Patient Search
  // ---------------------------------------------------------------------------

  Future<List<PatientModel>> searchPatients(String query) async {
    final lower = query.trim();
    final snap = await _patientsCol
        .orderBy('firstName')
        .startAt([lower])
        .endAt(['$lower\uf8ff'])
        .limit(20)
        .get();
    return snap.docs.map(PatientModel.fromFirestore).toList();
  }

  // ---------------------------------------------------------------------------
  // Audit Logs
  // ---------------------------------------------------------------------------

  Future<void> writeAuditLog({
    required String actorUid,
    required String action,
    String? recordRef,
  }) async {
    await _firestore.collection(AppConstants.auditLogsCollection).add({
      'actorUid': actorUid,
      'action': action,
      if (recordRef != null) 'recordRef': recordRef,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> auditLogsStream() {
    return _firestore
        .collection(AppConstants.auditLogsCollection)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
