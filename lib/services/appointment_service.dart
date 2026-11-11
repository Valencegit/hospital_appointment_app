import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/constants/app_constants.dart';
import '../models/appointment_model.dart';

/// Handles appointment booking via a Cloud Functions callable (which uses a
/// Firestore transaction internally) and all appointment queries / status
/// updates that are permitted directly from the client.
class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ── Patient: book appointment ─────────────────────────────────────────────
  /// Invokes the `bookAppointment` HTTPS callable Cloud Function.
  ///
  /// The function runs a Firestore transaction server-side to:
  ///   1. Verify the slot is still active and has capacity.
  ///   2. Atomically create the appointment document.
  ///   3. Increment `bookedCount` on the slot.
  ///
  /// Returns the new appointment document ID on success.
  /// Throws a descriptive [Exception] on failure (slot full, not found, etc.).
  Future<String> bookAppointment({
    required String patientId,
    required String patientName,
    required String slotId,
    required String departmentId,
    required String departmentName,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? notes,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'bookAppointment',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'patientId': patientId,
        'patientName': patientName,
        'slotId': slotId,
        'departmentId': departmentId,
        'departmentName': departmentName,
        // ISO-8601 string — Cloud Function parses this into a JS Date
        'appointmentDate': appointmentDate.toIso8601String(),
        'appointmentTime': appointmentTime,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

      final data = result.data;
      if (data['success'] == true && data['appointmentId'] != null) {
        return data['appointmentId'] as String;
      }
      throw Exception('Booking failed: unexpected response from server.');
    } on FirebaseFunctionsException catch (e) {
      // Map Cloud Function error codes to user-friendly messages
      switch (e.code) {
        case 'failed-precondition':
          throw Exception(e.message ?? 'This slot is no longer available.');
        case 'not-found':
          throw Exception('The selected slot could not be found.');
        case 'unauthenticated':
          throw Exception('You must be signed in to book an appointment.');
        case 'permission-denied':
          throw Exception('You are not permitted to book this appointment.');
        case 'deadline-exceeded':
          throw Exception('The booking request timed out. Please try again.');
        default:
          throw Exception(e.message ?? 'Booking failed. Please try again.');
      }
    } catch (e) {
      // Re-throw typed exceptions unchanged; wrap everything else
      if (e is Exception) rethrow;
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // ── Patient: stream own appointments ──────────────────────────────────────
  Stream<List<AppointmentModel>> patientAppointmentsStream(String patientId) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('patientId', isEqualTo: patientId)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  Stream<List<AppointmentModel>> doctorAppointmentsStream(String doctorId) {
    return _db
        .collection(AppConstants.appointmentsCollection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('appointmentDate')
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  /// Fetch a single appointment by ID.
  Future<AppointmentModel?> getAppointment(String id) async {
    final doc =
        await _db.collection(AppConstants.appointmentsCollection).doc(id).get();
    return doc.exists ? AppointmentModel.fromFirestore(doc) : null;
  }

  // ── Patient: request cancellation ─────────────────────────────────────────
  /// Writes a cancel-request status. Staff must approve via their dashboard.
  /// Firestore Security Rules allow patients to update only this limited
  /// set of fields on their own appointment document.
  Future<void> requestCancellation(String appointmentId, String reason) async {
    await _db
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId)
        .update({
      'status': AppConstants.statusCancelRequested,
      'cancellationReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Patient: request reschedule ───────────────────────────────────────────
  Future<void> requestReschedule(
      String appointmentId, String newSlotId, String newTime) async {
    await _db
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId)
        .update({
      'status': AppConstants.statusRescheduleRequested,
      'requestedSlotId': newSlotId,
      'requestedTime': newTime,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Staff: stream all appointments ────────────────────────────────────────
  Stream<List<AppointmentModel>> allAppointmentsStream({
    String? departmentId,
    String? status,
    DateTime? date,
  }) {
    Query q = _db.collection(AppConstants.appointmentsCollection);

    if (departmentId != null) {
      q = q.where('departmentId', isEqualTo: departmentId);
    }
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      q = q
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('appointmentDate', isLessThan: Timestamp.fromDate(end));
    }

    return q
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AppointmentModel.fromFirestore).toList());
  }

  // ── Staff: update appointment status ──────────────────────────────────────
  Future<void> updateStatus(String appointmentId, String newStatus,
      {String? reason}) async {
    final data = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (reason != null) data['cancellationReason'] = reason;
    await _db
        .collection(AppConstants.appointmentsCollection)
        .doc(appointmentId)
        .update(data);
  }

  // ── Admin / Staff: summary counts ─────────────────────────────────────────
  Future<Map<String, int>> getAppointmentSummary() async {
    final snap =
        await _db.collection(AppConstants.appointmentsCollection).get();
    final counts = <String, int>{
      'total': snap.size,
      AppConstants.statusPending: 0,
      AppConstants.statusConfirmed: 0,
      AppConstants.statusCancelled: 0,
      AppConstants.statusCompleted: 0,
    };
    for (final doc in snap.docs) {
      final s = doc['status'] as String? ?? '';
      if (counts.containsKey(s)) counts[s] = counts[s]! + 1;
    }
    return counts;
  }
}
