import 'package:cloud_firestore/cloud_firestore.dart';

class SlotModel {
  final String id;
  final String departmentId;
  final String departmentName;
  final String? doctorId;
  final String? doctorName;
  final DateTime date;
  final String startTime; // e.g. "09:00 AM"
  final String endTime; // e.g. "09:30 AM"
  final int capacity;
  final int bookedCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SlotModel({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    this.doctorId,
    this.doctorName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.bookedCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAvailable => isActive && (bookedCount < capacity);
  int get remainingSlots => capacity - bookedCount;

  factory SlotModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SlotModel(
      id: doc.id,
      departmentId: d['departmentId'] as String? ?? '',
      departmentName: d['departmentName'] as String? ?? '',
      doctorId: d['doctorId'] as String?,
      doctorName: d['doctorName'] as String?,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: d['startTime'] as String? ?? '',
      endTime: d['endTime'] as String? ?? '',
      capacity: d['capacity'] as int? ?? 1,
      bookedCount: d['bookedCount'] as int? ?? 0,
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'departmentId': departmentId,
        'departmentName': departmentName,
        if (doctorId != null) 'doctorId': doctorId,
        if (doctorName != null) 'doctorName': doctorName,
        'date': Timestamp.fromDate(date),
        'startTime': startTime,
        'endTime': endTime,
        'capacity': capacity,
        'bookedCount': bookedCount,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
