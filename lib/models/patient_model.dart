import 'package:cloud_firestore/cloud_firestore.dart';

/// Patient model containing demographic and clinical attributes.
class PatientModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? bloodGroup;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? medicalHistoryNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PatientModel._internal({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.medicalHistoryNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory PatientModel({
    required String uid,
    String? patientId,
    String? fullName,
    String firstName = '',
    String lastName = '',
    required String email,
    required String phoneNumber,
    dynamic dateOfBirth,
    String? gender,
    String? address,
    String? bloodGroup,
    String? emergencyContact,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalHistoryNotes,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    String first = firstName;
    String last = lastName;
    if (fullName != null && fullName.isNotEmpty && first.isEmpty && last.isEmpty) {
      final parts = fullName.trim().split(' ');
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    DateTime? dob;
    if (dateOfBirth is DateTime) {
      dob = dateOfBirth;
    } else if (dateOfBirth is Timestamp) {
      dob = dateOfBirth.toDate();
    } else if (dateOfBirth is String) {
      dob = DateTime.tryParse(dateOfBirth);
    }

    final ePhone = emergencyContactPhone ?? emergencyContact;

    return PatientModel._internal(
      uid: uid.isNotEmpty ? uid : (patientId ?? ''),
      firstName: first,
      lastName: last,
      email: email,
      phoneNumber: phoneNumber,
      dateOfBirth: dob,
      gender: gender,
      address: address,
      bloodGroup: bloodGroup,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: ePhone,
      medicalHistoryNotes: medicalHistoryNotes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get patientId => uid;

  String get fullName {
    final full = '$firstName $lastName'.trim();
    return full.isNotEmpty ? full : email;
  }

  String get emergencyContact {
    if (emergencyContactPhone != null && emergencyContactPhone!.isNotEmpty) {
      if (emergencyContactName != null && emergencyContactName!.isNotEmpty) {
        return '$emergencyContactName ($emergencyContactPhone)';
      }
      return emergencyContactPhone!;
    }
    return emergencyContactName ?? 'Not specified';
  }

  factory PatientModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final fullName = map['full_name'] as String? ?? (map['fullName'] as String? ?? '');
    String first = map['firstName'] as String? ?? (map['first_name'] as String? ?? '');
    String last = map['lastName'] as String? ?? (map['last_name'] as String? ?? '');
    if (first.isEmpty && last.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return PatientModel(
      uid: documentId ?? (map['uid'] as String? ?? (map['patient_id'] as String? ?? '')),
      firstName: first,
      lastName: last,
      email: map['email'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? (map['phoneNumber'] as String? ?? ''),
      dateOfBirth: map['dateOfBirth'] ?? map['date_of_birth'],
      gender: map['gender'] as String?,
      address: map['address'] as String?,
      bloodGroup: map['bloodGroup'] as String? ?? map['blood_group'] as String?,
      emergencyContactName: map['emergencyContactName'] as String? ?? map['emergency_contact_name'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String? ??
          map['emergency_contact_phone'] as String? ??
          map['emergencyContact'] as String? ??
          map['emergency_contact'] as String?,
      medicalHistoryNotes: map['medicalHistoryNotes'] as String? ?? map['medical_history_notes'] as String?,
      createdAt: parseDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: map['updatedAt'] != null || map['updated_at'] != null
          ? parseDateTime(map['updatedAt'] ?? map['updated_at'])
          : null,
    );
  }

  factory PatientModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return PatientModel.fromMap(data, documentId: doc.id);
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'full_name': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'phone_number': phoneNumber,
        if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
        if (gender != null) 'gender': gender,
        if (address != null) 'address': address,
        if (bloodGroup != null) 'bloodGroup': bloodGroup,
        if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
        if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
        if (medicalHistoryNotes != null) 'medicalHistoryNotes': medicalHistoryNotes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  Map<String, dynamic> toFirestore() => toMap();

  PatientModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalHistoryNotes,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      medicalHistoryNotes: medicalHistoryNotes ?? this.medicalHistoryNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
