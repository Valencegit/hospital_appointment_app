import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/enums/user_role.dart';

/// Base user model representing authenticated users in CarePulse Hospital.
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role; // 'patient', 'staff', 'doctor', 'receptionist', 'admin'
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.fullName = '',
    this.phoneNumber = '',
    required this.role,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Enum representation of the role.
  UserRole get userRole => UserRole.fromString(role);

  bool get isPatient => role == AppConstants.rolePatient;
  bool get isDoctor => role == AppConstants.roleDoctor;
  bool get isReceptionist => role == AppConstants.roleReceptionist;
  bool get isStaff =>
      role == AppConstants.roleStaff ||
      role == AppConstants.roleDoctor ||
      role == AppConstants.roleReceptionist ||
      role == AppConstants.roleSchedulingOfficer;
  bool get isAdmin => role == AppConstants.roleAdmin;

  /// First name extracted from full name.
  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  /// Last name extracted from full name.
  String get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  /// Display initials for avatars.
  String get initials {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UserModel(
      uid: documentId ?? (map['uid'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      fullName:
          map['full_name'] as String? ?? (map['fullName'] as String? ?? ''),
      phoneNumber: map['phone_number'] as String? ??
          (map['phoneNumber'] as String? ?? ''),
      role: (map['role'] as String? ?? AppConstants.rolePatient).toLowerCase(),
      photoUrl: map['photo_url'] as String? ?? map['photoUrl'] as String?,
      isActive: map['is_active'] as bool? ?? (map['isActive'] as bool? ?? true),
      createdAt: parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: map['updated_at'] != null || map['updatedAt'] != null
          ? parseDateTime(map['updated_at'] ?? map['updatedAt'])
          : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromMap(data, documentId: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'photo_url': photoUrl,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? role,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, fullName: $fullName, role: $role)';
}
