import * as admin from "firebase-admin";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";

// Booking request payload shape
interface BookingRequest {
  patientId: string;
  patientName: string;
  slotId: string;
  departmentId: string;
  departmentName: string;
  appointmentDate: string; // ISO-8601 string from Flutter
  appointmentTime: string;
  notes?: string;
}

/**
 * bookAppointment — HTTPS Callable (v2)
 *
 * Runs a Firestore transaction server-side to:
 *  1. Verify the slot is active and has remaining capacity.
 *  2. Atomically create the appointment document.
 *  3. Increment bookedCount on the slot.
 *
 * Returns { success: true, appointmentId: string } on success.
 * Throws HttpsError with a descriptive code on failure.
 */
export const bookAppointment = onCall(
  { enforceAppCheck: false }, // set to true if you enable App Check
  async (request: CallableRequest<BookingRequest>) => {
    // ── Authentication check ───────────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to book an appointment."
      );
    }
    if (request.auth.token.role !== "patient") {
      throw new HttpsError(
        "permission-denied",
        "Only patient accounts can book appointments."
      );
    }

    const {
      patientId,
      slotId,
      departmentId,
      notes,
    } = request.data;

    // ── Input validation ───────────────────────────────────────────────────
    if (!patientId || !slotId || !departmentId) {
      throw new HttpsError(
        "invalid-argument",
        "Missing required booking fields."
      );
    }

    // ── Authorisation: caller can only book for themselves ─────────────────
    if (request.auth.uid !== patientId) {
      throw new HttpsError(
        "permission-denied",
        "You can only book appointments for yourself."
      );
    }

    const db = admin.firestore();
    const patientDoc = await db.collection("users").doc(patientId).get();
    const patientData = patientDoc.data();
    if (
      !patientDoc.exists ||
      patientData?.role !== "patient" ||
      patientData?.is_active === false
    ) {
      throw new HttpsError(
        "permission-denied",
        "The patient account is not active."
      );
    }
    const patientName =
      patientData.full_name ?? patientData.fullName ?? "Patient";
    const slotRef = db.collection("appointment_slots").doc(slotId);
    let appointmentId = "";
    let appointmentDepartmentName = "hospital";

    // ── Firestore transaction ──────────────────────────────────────────────
    try {
      await db.runTransaction(async (transaction) => {
        const slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) {
          throw new HttpsError("not-found", "Slot not found.");
        }

        const slot = slotDoc.data()!;
        const bookedCount: number = slot.bookedCount ?? 0;
        const capacity: number = slot.capacity ?? 0;

        if (!slot.isActive) {
          throw new HttpsError(
            "failed-precondition",
            "This slot is no longer active."
          );
        }
        if (slot.departmentId !== departmentId) {
          throw new HttpsError(
            "failed-precondition",
            "The selected slot does not belong to this department."
          );
        }
        if (
          !(slot.date instanceof admin.firestore.Timestamp) ||
          typeof slot.startTime !== "string" ||
          typeof slot.departmentName !== "string"
        ) {
          throw new HttpsError(
            "failed-precondition",
            "The selected slot is missing required schedule details."
          );
        }
        appointmentDepartmentName = slot.departmentName;
        if (bookedCount >= capacity) {
          throw new HttpsError(
            "failed-precondition",
            "This slot is fully booked. Please choose another time."
          );
        }

        const appointmentRef = db.collection("appointments").doc();
        appointmentId = appointmentRef.id;

        transaction.set(appointmentRef, {
          patientId,
          patientName,
          slotId,
          departmentId: slot.departmentId,
          departmentName: slot.departmentName,
          doctorId: typeof slot.doctorId === "string" ? slot.doctorId : null,
          doctorName: typeof slot.doctorName === "string" ? slot.doctorName : null,
          appointmentDate: slot.date,
          appointmentTime: slot.startTime,
          status: "pending",
          notes: notes ?? null,
          bookedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: null,
        });

        transaction.update(slotRef, {
          bookedCount: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    } catch (err) {
      // Re-throw HttpsErrors unchanged; wrap anything else
      if (err instanceof HttpsError) throw err;
      throw new HttpsError("internal", "Booking failed due to a server error.");
    }

    // ── In-app notification (non-critical) ────────────────────────────────
    try {
      await db.collection("notifications").add({
        userId: patientId,
        title: "Appointment Requested",
        body: `Your ${appointmentDepartmentName} appointment is pending confirmation.`,
        type: "appointment_requested",
        appointmentId,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notification failure must not affect the booking result
    }

    return { success: true, appointmentId };
  }
);
