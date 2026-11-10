import * as admin from "firebase-admin";

// v2 imports — must match firebase-functions ^6.x
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

// Re-export the booking callable from appointments.ts
export { bookAppointment } from "./appointments";

// ─────────────────────────────────────────────────────────────────────────────
// Booking trigger: processes booking_requests documents transactionally
// ─────────────────────────────────────────────────────────────────────────────
export const processBookingRequest = onDocumentCreated(
  "booking_requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const requestId = event.params.requestId;
    const db = admin.firestore();

    const {
      patientId,
      patientName,
      slotId,
      departmentId,
      departmentName,
      appointmentDate,
      appointmentTime,
      notes,
    } = data;

    const slotRef = db.collection("slots").doc(slotId);
    const requestRef = db.collection("booking_requests").doc(requestId);

    try {
      let appointmentId = "";

      await db.runTransaction(async (transaction) => {
        const slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) throw new Error("Slot not found.");

        const slotData = slotDoc.data()!;
        const bookedCount: number = slotData.bookedCount ?? 0;
        const capacity: number = slotData.capacity ?? 0;
        const isActive: boolean = slotData.isActive ?? false;

        if (!isActive) throw new Error("This slot is no longer active.");
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
          notes: notes ?? null,
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
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Booking failed.";
      await requestRef.update({
        result: "error",
        error: message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// Admin creation: HTTPS callable — protected by a server-side secret.
//
// Never called from the public app UI. Run once from Firebase Shell / CLI:
//   firebase functions:shell
//   > createAdminUser({ secret: 'YOUR_SECRET', email: '...', ... })
// ─────────────────────────────────────────────────────────────────────────────
interface AdminUserRequest {
  secret: string;
  email: string;
  password: string;
  fullName: string;
  phoneNumber?: string;
}

export const createAdminUser = onCall(
  { enforceAppCheck: false },
  async (request: CallableRequest<AdminUserRequest>) => {
    const setupSecret = process.env.ADMIN_SETUP_SECRET ?? "";

    if (!setupSecret) {
      throw new HttpsError(
        "failed-precondition",
        "Admin setup secret is not configured on the server."
      );
    }

    if (request.data.secret !== setupSecret) {
      throw new HttpsError("permission-denied", "Invalid setup secret.");
    }

    const { email, password, fullName, phoneNumber } = request.data;

    if (!email || !password || !fullName) {
      throw new HttpsError(
        "invalid-argument",
        "email, password, and fullName are required."
      );
    }

    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: fullName,
      ...(phoneNumber ? { phoneNumber } : {}),
    });

    await db.collection("users").doc(userRecord.uid).set({
      uid: userRecord.uid,
      email,
      full_name: fullName,
      phone_number: phoneNumber ?? "",
      role: "admin",
      is_active: true,
      created_at: now,
      updated_at: null,
    });

    await db.collection("admins").doc(userRecord.uid).set({
      uid: userRecord.uid,
      full_name: fullName,
      email,
      phone_number: phoneNumber ?? "",
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
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// Scheduled reminders: runs daily at 08:00 EAT, notifies patients with
// appointments the following day.
// ─────────────────────────────────────────────────────────────────────────────
export const sendAppointmentReminders = onSchedule(
  {
    schedule: "0 8 * * *",
    timeZone: "Africa/Kampala",
  },
  async () => {
    const db = admin.firestore();
    const now = new Date();

    const tomorrowStart = new Date(now);
    tomorrowStart.setDate(now.getDate() + 1);
    tomorrowStart.setHours(0, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrowStart);
    tomorrowEnd.setHours(23, 59, 59, 999);

    const snap = await db
      .collection("appointments")
      .where(
        "appointmentDate",
        ">=",
        admin.firestore.Timestamp.fromDate(tomorrowStart)
      )
      .where(
        "appointmentDate",
        "<=",
        admin.firestore.Timestamp.fromDate(tomorrowEnd)
      )
      .where("status", "in", ["pending", "confirmed"])
      .get();

    for (const doc of snap.docs) {
      const appt = doc.data();
      const patientId: string = appt.patientId;

      const userDoc = await db.collection("users").doc(patientId).get();
      const token: string | undefined = userDoc.data()?.fcmToken;

      if (!token) continue;

      const message: admin.messaging.Message = {
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
      } catch (e) {
        console.error(`Failed to send reminder for appointment ${doc.id}:`, e);
      }
    }
  }
);
