import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums/user_role.dart';

/// Staff model representing doctors, specialists, nurses, and receptionists.
class StaffModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String employeeId;
  final String staffRole;
  final String? departmentId;
  final String departmentName;
  final String specialization;
  final String licenseNumber;
  final double consultationFee;
  final List<String> availableDays;
  final bool isAvailable;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StaffModel._internal({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.employeeId,
    required this.staffRole,
    this.departmentId,
    required this.departmentName,
    required this.specialization,
    required this.licenseNumber,
    required this.consultationFee,
    required this.availableDays,
    required this.isAvailable,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory StaffModel({
    required String uid,
    String? staffId,
    String? fullName,
    String firstName = '',
    String lastName = '',
    required String email,
    required String phoneNumber,
    String employeeId = '',
    dynamic role,
    String staffRole = 'staff',
    String? departmentId,
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
    bool isAvailable = true,
    bool isActive = true,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    String first = firstName;
    String last = lastName;
    if (fullName != null &&
        fullName.isNotEmpty &&
        first.isEmpty &&
        last.isEmpty) {
      final parts = fullName.trim().split(' ');
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    String sRole = staffRole;
    if (role is UserRole) {
      sRole = role.toValue();
    } else if (role is String && role.isNotEmpty) {
      sRole = role;
    }

    return StaffModel._internal(
      uid: uid.isNotEmpty ? uid : (staffId ?? ''),
      firstName: first,
      lastName: last,
      email: email,
      phoneNumber: phoneNumber,
      employeeId: employeeId,
      staffRole: sRole,
      departmentId: departmentId,
      departmentName: departmentName,
      specialization: specialization,
      licenseNumber: licenseNumber,
      consultationFee: consultationFee,
      availableDays: availableDays,
      isAvailable: isAvailable,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get staffId => employeeId.isNotEmpty ? employeeId : uid;

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  UserRole get role => UserRole.fromString(staffRole);

  factory StaffModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final fullName =
        map['full_name'] as String? ?? (map['fullName'] as String? ?? '');
    String first =
        map['firstName'] as String? ?? (map['first_name'] as String? ?? '');
    String last =
        map['lastName'] as String? ?? (map['last_name'] as String? ?? '');
    if (first.isEmpty && last.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return StaffModel(
      uid: documentId ??
          (map['uid'] as String? ?? (map['staff_id'] as String? ?? '')),
      firstName: first,
      lastName: last,
      email: map['email'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ??
          (map['phoneNumber'] as String? ?? ''),
      employeeId: map['employeeId'] as String? ??
          map['staffId'] as String? ??
          map['staff_id'] as String? ??
          '',
      staffRole:
          map['staffRole'] as String? ?? (map['role'] as String? ?? 'staff'),
      departmentId:
          map['departmentId'] as String? ?? map['department_id'] as String?,
      departmentName: map['departmentName'] as String? ??
          (map['department_name'] as String? ?? 'General Medicine'),
      specialization: map['specialization'] as String? ?? 'General Physician',
      licenseNumber: map['licenseNumber'] as String? ??
          (map['license_number'] as String? ?? ''),
      consultationFee: (map['consultationFee'] as num? ??
              map['consultation_fee'] as num? ??
              0.0)
          .toDouble(),
      availableDays: (map['availableDays'] as List<dynamic>? ??
              map['available_days'] as List<dynamic>? ??
              [])
          .map((e) => e.toString())
          .toList(),
      isAvailable:
          map['isAvailable'] as bool? ?? (map['is_available'] as bool? ?? true),
      isActive: map['isActive'] as bool? ?? (map['is_active'] as bool? ?? true),
      createdAt: parseDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: map['updatedAt'] != null || map['updated_at'] != null
          ? parseDateTime(map['updatedAt'] ?? map['updated_at'])
          : null,
    );
  }

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return StaffModel.fromMap(data, documentId: doc.id);
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'full_name': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'phone_number': phoneNumber,
        if (employeeId.isNotEmpty) 'employeeId': employeeId,
        if (employeeId.isNotEmpty) 'staffId': employeeId,
        if (employeeId.isNotEmpty) 'staff_id': employeeId,
        'staffRole': staffRole,
        'role': staffRole,
        if (departmentId != null) 'departmentId': departmentId,
        'departmentName': departmentName,
        'department_name': departmentName,
        'specialization': specialization,
        'licenseNumber': licenseNumber,
        'license_number': licenseNumber,
        'consultationFee': consultationFee,
        'consultation_fee': consultationFee,
        'availableDays': availableDays,
        'isAvailable': isAvailable,
        'is_available': isAvailable,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  Map<String, dynamic> toFirestore() => toMap();

  StaffModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? employeeId,
    String? staffRole,
    String? departmentId,
    String? departmentName,
    String? specialization,
    String? licenseNumber,
    double? consultationFee,
    List<String>? availableDays,
    bool? isAvailable,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return StaffModel(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      employeeId: employeeId ?? this.employeeId,
      staffRole: staffRole ?? this.staffRole,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      consultationFee: consultationFee ?? this.consultationFee,
      availableDays: availableDays ?? this.availableDays,
      isAvailable: isAvailable ?? this.isAvailable,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
