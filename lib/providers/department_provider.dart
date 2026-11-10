import 'package:flutter/material.dart';
import '../models/department_model.dart';
import '../models/slot_model.dart';
import '../services/firestore_service.dart';

/// State provider for department and slot management.
class DepartmentProvider extends ChangeNotifier {
  final FirestoreService _service;

  DepartmentProvider({FirestoreService? firestoreService})
      : _service = firestoreService ?? FirestoreService() {
    _loadDepartments();
  }

  bool _isLoading = false;
  String? _error;
  List<DepartmentModel> _departments = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<DepartmentModel> get departments =>
      List<DepartmentModel>.unmodifiable(_departments);

  Future<void> _loadDepartments() async {
    try {
      _departments = await _service.getAllDepartments();
      notifyListeners();
    } catch (_) {
      _departments = const [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<DepartmentModel>> activeDepartmentsStream() =>
      _service.activeDepartmentsStream();

  Stream<List<DepartmentModel>> departmentsStream() =>
      _service.departmentsStream();

  Stream<List<SlotModel>> slotsStream(String departmentId, DateTime date) =>
      _service.slotsForDepartment(departmentId, date);

  // ── Departments ────────────────────────────────────────────────────────────

  Future<bool> saveDepartment(DepartmentModel dept) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final existingDepartments = await _service.getAllDepartments();
      final normalizedName = dept.name.trim().toLowerCase();
      final isDuplicate = existingDepartments.any(
        (existing) => existing.name.trim().toLowerCase() == normalizedName,
      );
      if (isDuplicate && (dept.id.isEmpty ||
          existingDepartments.any((existing) =>
              existing.id != dept.id &&
              existing.name.trim().toLowerCase() == normalizedName))) {
        _error = 'A department with this name already exists.';
        return false;
      }
      await _service.saveDepartment(dept);
      return true;
    } catch (e) {
      _error = 'Failed to save department.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleDepartmentActive(DepartmentModel dept) async {
    try {
      await _service.updateDepartment(dept.id, {
        'isActive': !dept.isActive,
        'active_status': !dept.isActive,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Slots ──────────────────────────────────────────────────────────────────

  Future<bool> saveSlot(SlotModel slot) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.saveSlot(slot);
      return true;
    } catch (e) {
      _error = 'Failed to save slot.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSlotActive(SlotModel slot) async {
    try {
      await _service.updateSlot(slot.id, {'isActive': !slot.isActive});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<DepartmentModel>> getAllDepartments() =>
      _service.getAllDepartments();

  Future<List<SlotModel>> getAllSlots({String? departmentId}) =>
      _service.getAllSlots(departmentId: departmentId);
}
