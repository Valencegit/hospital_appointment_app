import 'package:cloud_firestore/cloud_firestore.dart';

/// Administrator model representing system superusers and operations directors.
class AdminModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String department;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdminModel._internal({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.department,
    required this.permissions,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminModel({
    required String uid,
    String? adminId,
    required String fullName,
    required String email,
    String phoneNumber = '',
    String department = 'Hospital Administration',
    List<String> permissions = const [
      'manage_users',
      'manage_staff',
      'manage_departments',
      'manage_slots',
      'view_analytics',
      'system_configuration',
    ],
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    return AdminModel._internal(
      uid: uid.isNotEmpty ? uid : (adminId ?? ''),
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      department: department,
      permissions: permissions,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get adminId => uid;

  factory AdminModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AdminModel(
      uid: documentId ?? (map['uid'] as String? ?? (map['admin_id'] as String? ?? '')),
      fullName: map['full_name'] as String? ?? (map['fullName'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? (map['phoneNumber'] as String? ?? ''),
      department: map['department'] as String? ?? 'Hospital Administration',
      permissions: (map['permissions'] as List<dynamic>? ?? const [
        'manage_users',
        'manage_staff',
        'manage_departments',
        'manage_slots',
        'view_analytics',
        'system_configuration',
      ]).map((e) => e.toString()).toList(),
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: map['updated_at'] != null || map['updatedAt'] != null
          ? parseDateTime(map['updated_at'] ?? map['updatedAt'])
          : null,
    );
  }

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AdminModel.fromMap(data, documentId: doc.id);
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'full_name': fullName,
        'fullName': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'phoneNumber': phoneNumber,
        'department': department,
        'permissions': permissions,
        'created_at': Timestamp.fromDate(createdAt),
        'createdAt': Timestamp.fromDate(createdAt),
        'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  Map<String, dynamic> toFirestore() => toMap();

  AdminModel copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? department,
    List<String>? permissions,
    DateTime? updatedAt,
  }) {
    return AdminModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
