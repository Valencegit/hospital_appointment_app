import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String name;
  final String? description;
  final String? iconName;    // icon identifier for display
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      iconName: d['iconName'] as String?,
      isActive: d['isActive'] as bool? ??
          d['active_status'] as bool? ??
          true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (description != null) 'description': description,
        if (iconName != null) 'iconName': iconName,
        'isActive': isActive,
        'active_status': isActive,
        'department_id': id,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  DepartmentModel copyWith({
    String? name,
    String? description,
    String? iconName,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return DepartmentModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
