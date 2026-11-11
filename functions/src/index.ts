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
      slotId,
      departmentId,
      notes,
    } = data;

    const slotRef = db.collection("appointment_slots").doc(slotId);
    const requestRef = db.collection("booking_requests").doc(requestId);

    try {
      const patientDoc = await db.collection("users").doc(patientId).get();
      const patientData = patientDoc.data();
      if (
        !patientDoc.exists ||
        patientData?.role !== "patient" ||
        patientData?.is_active === false
      ) {
        throw new Error("The patient account is not active.");
      }
      const patientName =
        patientData.full_name ?? patientData.fullName ?? "Patient";
      let appointmentId = "";
      let appointmentDepartmentName = "hospital";

      await db.runTransaction(async (transaction) => {
        const slotDoc = await transaction.get(slotRef);

        if (!slotDoc.exists) throw new Error("Slot not found.");

        const slotData = slotDoc.data()!;
        const bookedCount: number = slotData.bookedCount ?? 0;
        const capacity: number = slotData.capacity ?? 0;
        const isActive: boolean = slotData.isActive ?? false;

        if (!isActive) throw new Error("This slot is no longer active.");
        if (slotData.departmentId !== departmentId) {
          throw new Error("The selected slot does not match the department.");
        }
        appointmentDepartmentName = slotData.departmentName ?? "hospital";
        if (bookedCount >= capacity) {
          throw new Error("This slot is fully booked. Please select another slot.");
        }

        const appointmentRef = db.collection("appointments").doc();
        appointmentId = appointmentRef.id;

        transaction.set(appointmentRef, {
          patientId,
          patientName,
          slotId,
          departmentId: slotData.departmentId,
          departmentName: slotData.departmentName ?? "",
          doctorId:
            typeof slotData.doctorId === "string" ? slotData.doctorId : null,
          doctorName:
            typeof slotData.doctorName === "string" ? slotData.doctorName : null,
          appointmentDate: slotData.date,
          appointmentTime: slotData.startTime,
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
        body: `Your ${appointmentDepartmentName} appointment is pending confirmation.`,
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

    await admin.auth().setCustomUserClaims(userRecord.uid, { role: "admin" });

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

const assignedRoles = [
  "patient",
  "receptionist",
  "doctor",
  "scheduling_officer",
  "admin",
] as const;

type AssignedRole = (typeof assignedRoles)[number];

interface AssignRoleRequest {
  uid: string;
  role: AssignedRole;
}

export const ensurePatientRole = onCall(
  { enforceAppCheck: false },
  async (request: CallableRequest<unknown>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to continue.");
    }

    const userRef = admin.firestore().collection("users").doc(request.auth.uid);
    const userDoc = await userRef.get();
    const userData = userDoc.data();
    if (
      !userDoc.exists ||
      userData?.role !== "patient" ||
      userData?.is_active === false ||
      request.auth.token.role != null
    ) {
      throw new HttpsError(
        "permission-denied",
        "Only an active patient account can receive the patient role."
      );
    }

    await admin.auth().setCustomUserClaims(request.auth.uid, {
      ...((await admin.auth().getUser(request.auth.uid)).customClaims ?? {}),
      role: "patient",
    });
    return { role: "patient" };
  }
);

export const assignUserRole = onCall(
  { enforceAppCheck: false },
  async (request: CallableRequest<AssignRoleRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to continue.");
    }
    if (request.auth.token.role !== "admin") {
      throw new HttpsError("permission-denied", "Administrator access required.");
    }

    const { uid, role } = request.data;
    if (
      typeof uid !== "string" ||
      uid.length === 0 ||
      typeof role !== "string" ||
      !assignedRoles.includes(role as AssignedRole)
    ) {
      throw new HttpsError("invalid-argument", "A valid user and role are required.");
    }
    if (uid === request.auth.uid) {
      throw new HttpsError(
        "failed-precondition",
        "Administrators cannot change their own role."
      );
    }

    const auth = admin.auth();
    let target: admin.auth.UserRecord;
    try {
      target = await auth.getUser(uid);
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "auth/user-not-found"
      ) {
        throw new HttpsError("not-found", "User account not found.");
      }
      throw error;
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Hospital user profile not found.");
    }
    const existingRole = userDoc.data()?.role;
    if (
      existingRole === "admin" &&
      role !== "admin" &&
      (await db.collection("users")
        .where("role", "==", "admin")
        .where("is_active", "==", true)
        .get()).size <= 1
    ) {
      throw new HttpsError(
        "failed-precondition",
        "The last active administrator cannot be demoted."
      );
    }

    const batch = db.batch();
    batch.update(userRef, {
      role,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    const staffRef = db.collection("staff").doc(uid);
    if (role === "doctor" || role === "receptionist" || role === "scheduling_officer") {
      batch.set(
        staffRef,
        { uid, staffRole: role, role, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true }
      );
    } else if (role === "patient" || role === "admin") {
      batch.delete(staffRef);
    }
    batch.set(db.collection("audit_logs").doc(), {
      actorUid: request.auth.uid,
      action: "user_role_changed",
      targetId: uid,
      role,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    await auth.setCustomUserClaims(uid, {
      ...(target.customClaims ?? {}),
      role,
    });

    return { success: true, uid, role };
  }
);

interface AccountStatusRequest {
  uid: string;
  active: boolean;
}

export const setUserAccountStatus = onCall(
  { enforceAppCheck: false },
  async (request: CallableRequest<AccountStatusRequest>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to continue.");
    }
    if (request.auth.token.role !== "admin") {
      throw new HttpsError("permission-denied", "Administrator access required.");
    }
    const { uid, active } = request.data;
    if (typeof uid !== "string" || uid.length === 0 || typeof active !== "boolean") {
      throw new HttpsError("invalid-argument", "A user and account status are required.");
    }
    if (uid === request.auth.uid && !active) {
      throw new HttpsError(
        "failed-precondition",
        "Administrators cannot deactivate their own account."
      );
    }

    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Hospital user profile not found.");
    }
    if (
      !active &&
      userDoc.data()?.role === "admin" &&
      (await db.collection("users")
        .where("role", "==", "admin")
        .where("is_active", "==", true)
        .get()).size <= 1
    ) {
      throw new HttpsError(
        "failed-precondition",
        "The last active administrator cannot be deactivated."
      );
    }
    await userRef.update({
      is_active: active,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    await admin.auth().updateUser(uid, { disabled: !active });
    await db.collection("audit_logs").add({
      actorUid: request.auth.uid,
      action: active ? "user_activated" : "user_deactivated",
      targetId: uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true };
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
