"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendAppointmentReminders = exports.createAdminUser = exports.processBookingRequest = exports.bookAppointment = void 0;
const admin = require("firebase-admin");
// v2 imports — must match firebase-functions ^6.x
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
admin.initializeApp();
// Re-export the booking callable from appointments.ts
var appointments_1 = require("./appointments");
Object.defineProperty(exports, "bookAppointment", { enumerable: true, get: function () { return appointments_1.bookAppointment; } });
// ─────────────────────────────────────────────────────────────────────────────
// Booking trigger: processes booking_requests documents transactionally
// ─────────────────────────────────────────────────────────────────────────────
exports.processBookingRequest = (0, firestore_1.onDocumentCreated)("booking_requests/{requestId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const requestId = event.params.requestId;
    const db = admin.firestore();
    const { patientId, patientName, slotId, departmentId, departmentName, appointmentDate, appointmentTime, notes, } = data;
    const slotRef = db.collection("slots").doc(slotId);
    const requestRef = db.collection("booking_requests").doc(requestId);
    try {
        let appointmentId = "";
        await db.runTransaction(async (transaction) => {
            var _a, _b, _c;
            const slotDoc = await transaction.get(slotRef);
            if (!slotDoc.exists)
                throw new Error("Slot not found.");
            const slotData = slotDoc.data();
            const bookedCount = (_a = slotData.bookedCount) !== null && _a !== void 0 ? _a : 0;
            const capacity = (_b = slotData.capacity) !== null && _b !== void 0 ? _b : 0;
            const isActive = (_c = slotData.isActive) !== null && _c !== void 0 ? _c : false;
            if (!isActive)
                throw new Error("This slot is no longer active.");
            if (bookedCount >= capacity) {
                throw new Error("This slot is fully booked. Please select another slot.");
            }
            const appointmentRef = db.collection("appointments").doc();
            appointmentId = appointmentRef.id;
            transaction.set(appointmentRef, {
                patientId,
                patientName,
                slotId,
                departmentId,
                departmentName,
                appointmentDate,
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
        await requestRef.update({
            result: "success",
            appointmentId,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
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
    catch (err) {
        const message = err instanceof Error ? err.message : "Booking failed.";
        await requestRef.update({
            result: "error",
            error: message,
            processedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
});
exports.createAdminUser = (0, https_1.onCall)({ enforceAppCheck: false }, async (request) => {
    var _a;
    const setupSecret = (_a = process.env.ADMIN_SETUP_SECRET) !== null && _a !== void 0 ? _a : "";
    if (!setupSecret) {
        throw new https_1.HttpsError("failed-precondition", "Admin setup secret is not configured on the server.");
    }
    if (request.data.secret !== setupSecret) {
        throw new https_1.HttpsError("permission-denied", "Invalid setup secret.");
    }
    const { email, password, fullName, phoneNumber } = request.data;
    if (!email || !password || !fullName) {
        throw new https_1.HttpsError("invalid-argument", "email, password, and fullName are required.");
    }
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    const userRecord = await admin.auth().createUser(Object.assign({ email,
        password, displayName: fullName }, (phoneNumber ? { phoneNumber } : {})));
    await db.collection("users").doc(userRecord.uid).set({
        uid: userRecord.uid,
        email,
        full_name: fullName,
        phone_number: phoneNumber !== null && phoneNumber !== void 0 ? phoneNumber : "",
        role: "admin",
        is_active: true,
        created_at: now,
        updated_at: null,
    });
    await db.collection("admins").doc(userRecord.uid).set({
        uid: userRecord.uid,
        full_name: fullName,
        email,
        phone_number: phoneNumber !== null && phoneNumber !== void 0 ? phoneNumber : "",
        department: "Hospital Administration",
        permissions: [
            "manage_users",
            "manage_staff",
            "manage_departments",
            "manage_slots",
            "view_analytics",
            "system_configuration",
        ],
        created_at: now,
        updated_at: null,
    });
    await db.collection("audit_logs").add({
        actorUid: "system",
        action: "admin_account_created",
        recordRef: userRecord.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        uid: userRecord.uid,
        message: `Admin account created for ${email}`,
    };
});
// ─────────────────────────────────────────────────────────────────────────────
// Scheduled reminders: runs daily at 08:00 EAT, notifies patients with
// appointments the following day.
// ─────────────────────────────────────────────────────────────────────────────
exports.sendAppointmentReminders = (0, scheduler_1.onSchedule)({
    schedule: "0 8 * * *",
    timeZone: "Africa/Kampala",
}, async () => {
    var _a;
    const db = admin.firestore();
    const now = new Date();
    const tomorrowStart = new Date(now);
    tomorrowStart.setDate(now.getDate() + 1);
    tomorrowStart.setHours(0, 0, 0, 0);
    const tomorrowEnd = new Date(tomorrowStart);
    tomorrowEnd.setHours(23, 59, 59, 999);
    const snap = await db
        .collection("appointments")
        .where("appointmentDate", ">=", admin.firestore.Timestamp.fromDate(tomorrowStart))
        .where("appointmentDate", "<=", admin.firestore.Timestamp.fromDate(tomorrowEnd))
        .where("status", "in", ["pending", "confirmed"])
        .get();
    for (const doc of snap.docs) {
        const appt = doc.data();
        const patientId = appt.patientId;
        const userDoc = await db.collection("users").doc(patientId).get();
        const token = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken;
        if (!token)
            continue;
        const message = {
            token,
            notification: {
                title: "Appointment Tomorrow",
                body: `Reminder: You have a ${appt.departmentName} appointment tomorrow at ${appt.appointmentTime}.`,
            },
            data: {
                type: "reminder",
                appointmentId: doc.id,
            },
            android: {
                notification: { channelId: "hospital_appointments" },
            },
        };
        try {
            await admin.messaging().send(message);
            await db.collection("notifications").add({
                userId: patientId,
                title: "Appointment Tomorrow",
                body: `Reminder: ${appt.departmentName} appointment tomorrow at ${appt.appointmentTime}.`,
                type: "reminder",
                appointmentId: doc.id,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        catch (e) {
            console.error(`Failed to send reminder for appointment ${doc.id}:`, e);
        }
    }
});
//# sourceMappingURL=index.js.map