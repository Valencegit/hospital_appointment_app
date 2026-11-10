"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.bookAppointment = void 0;
const admin = require("firebase-admin");
const https_1 = require("firebase-functions/v2/https");
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
exports.bookAppointment = (0, https_1.onCall)({ enforceAppCheck: false }, // set to true if you enable App Check
async (request) => {
    // ── Authentication check ───────────────────────────────────────────────
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "You must be signed in to book an appointment.");
    }
    const { patientId, patientName, slotId, departmentId, departmentName, appointmentDate, appointmentTime, notes, } = request.data;
    // ── Input validation ───────────────────────────────────────────────────
    if (!patientId || !slotId || !departmentId || !appointmentDate || !appointmentTime) {
        throw new https_1.HttpsError("invalid-argument", "Missing required booking fields.");
    }
    // ── Authorisation: caller can only book for themselves ─────────────────
    if (request.auth.uid !== patientId) {
        throw new https_1.HttpsError("permission-denied", "You can only book appointments for yourself.");
    }
    const db = admin.firestore();
    const slotRef = db.collection("slots").doc(slotId);
    let appointmentId = "";
    // ── Firestore transaction ──────────────────────────────────────────────
    try {
        await db.runTransaction(async (transaction) => {
            var _a, _b;
            const slotDoc = await transaction.get(slotRef);
            if (!slotDoc.exists) {
                throw new https_1.HttpsError("not-found", "Slot not found.");
            }
            const slot = slotDoc.data();
            const bookedCount = (_a = slot.bookedCount) !== null && _a !== void 0 ? _a : 0;
            const capacity = (_b = slot.capacity) !== null && _b !== void 0 ? _b : 0;
            if (!slot.isActive) {
                throw new https_1.HttpsError("failed-precondition", "This slot is no longer active.");
            }
            if (bookedCount >= capacity) {
                throw new https_1.HttpsError("failed-precondition", "This slot is fully booked. Please choose another time.");
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
                notes: notes !== null && notes !== void 0 ? notes : null,
                bookedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: null,
            });
            transaction.update(slotRef, {
                bookedCount: admin.firestore.FieldValue.increment(1),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
    }
    catch (err) {
        // Re-throw HttpsErrors unchanged; wrap anything else
        if (err instanceof https_1.HttpsError)
            throw err;
        throw new https_1.HttpsError("internal", "Booking failed due to a server error.");
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
    }
    catch (_) {
        // Notification failure must not affect the booking result
    }
    return { success: true, appointmentId };
});
//# sourceMappingURL=appointments.js.map