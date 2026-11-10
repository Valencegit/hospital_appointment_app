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

    const {
      patientId,
      patientName,
      slotId,
      departmentId,
      departmentName,
      appointmentDate,
      appointmentTime,
      notes,
    } = request.data;

    // ── Input validation ───────────────────────────────────────────────────
    if (!patientId || !slotId || !departmentId || !appointmentDate || !appointmentTime) {
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
    const slotRef = db.collection("slots").doc(slotId);
    let appointmentId = "";

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
          departmentId,
          departmentName,
          appointmentDate: new Date(appointmentDate),
          appointmentTime,
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
        body: `Your ${departmentName} appointment at ${appointmentTime} is pending confirmation.`,
        type: "booking_confirmed",
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
