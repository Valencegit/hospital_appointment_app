import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String slotId;
  final String departmentId;
  final String departmentName;
  final String? doctorId;
  final String? doctorName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? notes;
  final String? cancellationReason;
  final DateTime bookedAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.slotId,
    required this.departmentId,
    required this.departmentName,
    this.doctorId,
    this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = AppConstants.statusPending,
    this.notes,
    this.cancellationReason,
    required this.bookedAt,
    this.updatedAt,
  });

  bool get isPending => status == AppConstants.statusPending;
  bool get isConfirmed => status == AppConstants.statusConfirmed;
  bool get isCancelled => status == AppConstants.statusCancelled;
  bool get isCompleted => status == AppConstants.statusCompleted;

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      patientId: d['patientId'] as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      slotId: d['slotId'] as String? ?? '',
      departmentId: d['departmentId'] as String? ?? '',
      departmentName: d['departmentName'] as String? ?? '',
      doctorId: d['doctorId'] as String?,
      doctorName: d['doctorName'] as String?,
      appointmentDate:
          (d['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: d['appointmentTime'] as String? ?? '',
      status: d['status'] as String? ?? AppConstants.statusPending,
      notes: d['notes'] as String?,
      cancellationReason: d['cancellationReason'] as String?,
      bookedAt: (d['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'patientId': patientId,
        'patientName': patientName,
        'slotId': slotId,
        'departmentId': departmentId,
        'departmentName': departmentName,
        if (doctorId != null) 'doctorId': doctorId,
        if (doctorName != null) 'doctorName': doctorName,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'status': status,
        if (notes != null) 'notes': notes,
        if (cancellationReason != null)
          'cancellationReason': cancellationReason,
        'bookedAt': Timestamp.fromDate(bookedAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  AppointmentModel copyWith({
    String? status,
    String? notes,
    String? cancellationReason,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      slotId: slotId,
      departmentId: departmentId,
      departmentName: departmentName,
      doctorId: doctorId,
      doctorName: doctorName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      bookedAt: bookedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
