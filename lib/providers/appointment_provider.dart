import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

/// State provider for appointment booking, listing, and status management.
class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _service;

  AppointmentProvider({AppointmentService? service})
      : _service = service ?? AppointmentService();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<AppointmentModel>> patientAppointmentsStream(String patientId) =>
      _service.patientAppointmentsStream(patientId);

  Stream<List<AppointmentModel>> doctorAppointmentsStream(String doctorId) =>
      _service.doctorAppointmentsStream(doctorId);

  Stream<List<AppointmentModel>> departmentAppointmentsStream(
          String departmentId) =>
      _service.allAppointmentsStream(departmentId: departmentId);

  Stream<List<AppointmentModel>> allAppointmentsStream({
    String? departmentId,
    String? status,
    DateTime? date,
  }) =>
      _service.allAppointmentsStream(
          departmentId: departmentId, status: status, date: date);

  // ── Book appointment ───────────────────────────────────────────────────────

  Future<String?> book({
    required String patientId,
    required String patientName,
    required String slotId,
    required String departmentId,
    required String departmentName,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final id = await _service.bookAppointment(
        patientId: patientId,
        patientName: patientName,
        slotId: slotId,
        departmentId: departmentId,
        departmentName: departmentName,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        notes: notes,
      );
      return id;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Request cancellation ──────────────────────────────────────────────────

  Future<bool> requestCancellation(String appointmentId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.requestCancellation(appointmentId, reason);
      return true;
    } catch (e) {
      _error = 'Failed to submit cancellation request.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Request reschedule ────────────────────────────────────────────────────

  Future<bool> requestReschedule(
      String appointmentId, String newSlotId, String newTime) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.requestReschedule(appointmentId, newSlotId, newTime);
      return true;
    } catch (e) {
      _error = 'Failed to submit reschedule request.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Staff: update status ──────────────────────────────────────────────────

  Future<bool> updateStatus(String appointmentId, String newStatus,
      {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateStatus(appointmentId, newStatus, reason: reason);
      return true;
    } catch (e) {
      _error = 'Failed to update appointment status.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Summary ───────────────────────────────────────────────────────────────

  Future<Map<String, int>> getSummary() => _service.getAppointmentSummary();
}
