import * as admin from "firebase-admin";

// v2 imports — must match firebase-functions ^6.x
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

admin.initializeApp();

// Re-export the booking callable from appointments.ts
export { bookAppointment } from "./appointments";

// ─────────────────────────────────────────────────────────────────────────────
// Patient ID generation
//
// Called automatically when a new document is created in the `patients/`
// collection. Assigns a sequential HMS-PAT-XXXXXX hospital ID using a
// Firestore counter transaction so IDs are always unique and monotonic.
//
// The ID is written back to both `patients/{uid}.patientId` and
// `users/{uid}.patientId` so both collections stay in sync.
// ─────────────────────────────────────────────────────────────────────────────
export const assignPatientId = onDocumentCreated(
  "patients/{uid}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const uid = event.params.uid;
    const data = snap.data();

    // Skip if a Patient ID was already assigned (re-triggered doc)
    if (typeof data.patientId === "string" && data.patientId.startsWith("HMS-PAT-")) {
      return;
    }

    const db = admin.firestore();
    const counterRef = db.collection("counters").doc("patients");
    const patientRef = db.collection("patients").doc(uid);
    const userRef    = db.collection("users").doc(uid);

    let patientId = "";

    await db.runTransaction(async (tx) => {
      const counter = await tx.get(counterRef);
      const lastNumber: number = counter.exists
        ? (counter.data()?.lastNumber ?? 0)
        : 0;
      const nextNumber = lastNumber + 1;
      patientId = `HMS-PAT-${String(nextNumber).padStart(6, "0")}`;

      tx.set(counterRef, { lastNumber: nextNumber }, { merge: true });
      tx.update(patientRef, { patientId });
    });

    // Mirror the ID onto the users document (best-effort, non-critical)
    try {
      await userRef.update({ patientId });
    } catch {
      // users/ document may not exist yet during early registration
    }

    console.log(`[assignPatientId] Assigned ${patientId} to patient ${uid}`);
  }
);

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
    const bootstrapRef = db.collection("system_settings").doc("admin_bootstrap");
    await db.runTransaction(async (transaction) => {
      const bootstrap = await transaction.get(bootstrapRef);
      if (bootstrap.exists) {
        throw new HttpsError(
          "failed-precondition",
          "Initial administrator setup is already complete or in progress."
        );
      }
      transaction.create(bootstrapRef, {
        email: email.trim().toLowerCase(),
        startedAt: now,
      });
    });

    let hasExistingAdmin: boolean;
    try {
      const existingAdmins = await db
        .collection("users")
        .where("role", "==", "admin")
        .where("is_active", "==", true)
        .limit(1)
        .get();
      hasExistingAdmin = !existingAdmins.empty;
    } catch (error) {
      try {
        await bootstrapRef.delete();
      } catch (cleanupError) {
        console.error("Could not release initial-admin setup lock:", cleanupError);
      }
      throw error;
    }
    if (hasExistingAdmin) {
      await bootstrapRef.delete();
      throw new HttpsError(
        "failed-precondition",
        "Initial administrator setup is already complete."
      );
    }

    let userRecord: admin.auth.UserRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: fullName,
        ...(phoneNumber ? { phoneNumber } : {}),
      });
    } catch (error) {
      try {
        await bootstrapRef.delete();
      } catch (cleanupError) {
        console.error("Could not release initial-admin setup lock:", cleanupError);
      }
      throw error;
    }
    const userRef = db.collection("users").doc(userRecord.uid);
    const adminRef = db.collection("admins").doc(userRecord.uid);
    const auditRef = db.collection("audit_logs").doc();
    try {
      const batch = db.batch();
      batch.set(userRef, {
        uid: userRecord.uid,
        email,
        full_name: fullName,
        phone_number: phoneNumber ?? "",
        role: "admin",
        is_active: true,
        created_at: now,
        updated_at: null,
      });
      batch.set(adminRef, {
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
      batch.set(auditRef, {
        actorUid: "system",
        action: "admin_account_created",
        recordRef: userRecord.uid,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await admin.auth().setCustomUserClaims(userRecord.uid, { role: "admin" });
    } catch (error) {
      try {
        const rollback = db.batch();
        rollback.delete(userRef);
        rollback.delete(adminRef);
        rollback.delete(auditRef);
        rollback.delete(bootstrapRef);
        await rollback.commit();
        await admin.auth().deleteUser(userRecord.uid);
      } catch (rollbackError) {
        console.error(
          `Could not roll back incomplete initial admin ${userRecord.uid}:`,
          rollbackError
        );
      }
      console.error("Could not provision initial admin:", error);
      throw new HttpsError(
        "internal",
        "Initial administrator setup failed. Contact Firebase support if the account still exists."
      );
    }

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

async function requireActiveAdmin(
  request: CallableRequest<unknown>
): Promise<string> {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Sign in to continue.");
  }
  if (auth.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Administrator access required.");
  }

  const adminDoc = await admin.firestore().collection("users").doc(auth.uid).get();
  const adminData = adminDoc.data();
  if (
    !adminDoc.exists ||
    adminData?.role !== "admin" ||
    adminData?.is_active === false
  ) {
    throw new HttpsError("permission-denied", "An active administrator is required.");
  }
  return auth.uid;
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
    const adminUid = await requireActiveAdmin(request);

    const { uid, role } = request.data;
    if (
      typeof uid !== "string" ||
      uid.length === 0 ||
      typeof role !== "string" ||
      !assignedRoles.includes(role as AssignedRole)
    ) {
      throw new HttpsError("invalid-argument", "A valid user and role are required.");
    }
    if (uid === adminUid) {
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
    const staffRef = db.collection("staff").doc(uid);
    if (
      role === "doctor" ||
      role === "receptionist" ||
      role === "scheduling_officer"
    ) {
      const staffDoc = await staffRef.get();
      const staffData = staffDoc.data();
      const employeeId =
        staffData?.employeeId ?? staffData?.staffId ?? staffData?.staff_id;
      const departmentId =
        staffData?.departmentId ?? staffData?.department_id;
      if (!staffDoc.exists || !employeeId || !departmentId) {
        throw new HttpsError(
          "failed-precondition",
          "Create the staff account with its staff ID and department before assigning this role."
        );
      }
    }
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
    if (
      role === "doctor" ||
      role === "receptionist" ||
      role === "scheduling_officer"
    ) {
      batch.update(staffRef, {
        staffRole: role,
        role,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else if (role === "patient" || role === "admin") {
      batch.delete(staffRef);
    }
    batch.set(db.collection("audit_logs").doc(), {
      actorUid: adminUid,
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

interface CreateStaffUserRequest {
  fullName: string;
  email: string;
  phoneNumber: string;
  employeeId: string;
  departmentId: string;
  role: "receptionist" | "doctor" | "scheduling_officer";
  specialization?: string;
}

export const createStaffUser = onCall(
  { enforceAppCheck: false },
  async (request: CallableRequest<CreateStaffUserRequest>) => {
    const adminUid = await requireActiveAdmin(request);
    const {
      fullName,
      email,
      phoneNumber,
      employeeId,
      departmentId,
      role,
      specialization,
    } = request.data;
    const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";
    const normalizedName = typeof fullName === "string" ? fullName.trim() : "";
    const normalizedPhone = typeof phoneNumber === "string" ? phoneNumber.trim() : "";
    const normalizedEmployeeId =
      typeof employeeId === "string" ? employeeId.trim() : "";

    if (
      !normalizedName ||
      !normalizedEmail ||
      !normalizedPhone ||
      !normalizedEmployeeId ||
      typeof departmentId !== "string" ||
      !departmentId.trim() ||
      !["receptionist", "doctor", "scheduling_officer"].includes(role)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Name, email, phone, staff ID, department, and a valid staff role are required."
      );
    }
    if (
      role === "doctor" &&
      (typeof specialization !== "string" || !specialization.trim())
    ) {
      throw new HttpsError(
        "invalid-argument",
        "A specialization is required for doctor accounts."
      );
    }

    const db = admin.firestore();
    const departmentDoc = await db
      .collection("departments")
      .doc(departmentId.trim())
      .get();
    const department = departmentDoc.data();
    const departmentIsActive =
      department?.isActive ?? department?.active_status ?? true;
    if (!departmentDoc.exists || departmentIsActive !== true) {
      throw new HttpsError("failed-precondition", "Select an active department.");
    }
    const departmentName =
      typeof department?.name === "string" ? department.name : "";
    if (!departmentName) {
      throw new HttpsError("failed-precondition", "The department has no name.");
    }

    const duplicateEmployeeId = await db
      .collection("staff")
      .where("employeeId", "==", normalizedEmployeeId)
      .limit(1)
      .get();
    if (!duplicateEmployeeId.empty) {
      throw new HttpsError("already-exists", "That staff ID is already in use.");
    }

    const auth = admin.auth();
    let createdUser: admin.auth.UserRecord;
    try {
      createdUser = await auth.createUser({
        email: normalizedEmail,
        displayName: normalizedName,
        emailVerified: false,
      });
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "auth/email-already-exists"
      ) {
        throw new HttpsError("already-exists", "An account already uses this email.");
      }
      throw error;
    }

    const now = admin.firestore.Timestamp.now();
    const nameParts = normalizedName.split(/\s+/);
    const userRef = db.collection("users").doc(createdUser.uid);
    const staffRef = db.collection("staff").doc(createdUser.uid);
    const auditRef = db.collection("audit_logs").doc();

    try {
      const batch = db.batch();
      batch.set(userRef, {
        uid: createdUser.uid,
        email: normalizedEmail,
        full_name: normalizedName,
        phone_number: normalizedPhone,
        role,
        staff_id: normalizedEmployeeId,
        department_id: departmentId.trim(),
        department_name: departmentName,
        is_active: true,
        created_at: now,
        updated_at: null,
      });
      batch.set(staffRef, {
        uid: createdUser.uid,
        firstName: nameParts[0],
        lastName: nameParts.slice(1).join(" "),
        full_name: normalizedName,
        email: normalizedEmail,
        phoneNumber: normalizedPhone,
        phone_number: normalizedPhone,
        staffRole: role,
        role,
        employeeId: normalizedEmployeeId,
        staffId: normalizedEmployeeId,
        departmentId: departmentId.trim(),
        department_id: departmentId.trim(),
        departmentName,
        department_name: departmentName,
        specialization: role === "doctor" ? specialization!.trim() : "",
        licenseNumber: "",
        license_number: "",
        consultationFee: 0,
        consultation_fee: 0,
        availableDays: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
        isAvailable: true,
        is_available: true,
        isActive: true,
        is_active: true,
        createdAt: now,
        created_at: now,
        updatedAt: null,
        updated_at: null,
      });
      batch.set(auditRef, {
        actorUid: adminUid,
        action: "staff_account_created",
        targetId: createdUser.uid,
        role,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await auth.setCustomUserClaims(createdUser.uid, { role });
    } catch (error) {
      try {
        const rollback = db.batch();
        rollback.delete(userRef);
        rollback.delete(staffRef);
        rollback.delete(auditRef);
        await rollback.commit();
        await auth.deleteUser(createdUser.uid);
      } catch (rollbackError) {
        console.error(
          `Could not roll back incomplete staff account ${createdUser.uid}:`,
          rollbackError
        );
      }
      console.error("Could not provision staff account:", error);
      throw new HttpsError(
        "internal",
        "Staff account setup failed. Contact an administrator if the account still appears."
      );
    }

    return { success: true, uid: createdUser.uid, email: normalizedEmail, role };
  }
);

interface AccountStatusRequest {
  uid: string;
  active: boolean;
}

export const setUserAccountStatus = onCall(
  { enforceAppCheck: false },
  async (request: CallableRequest<AccountStatusRequest>) => {
    const adminUid = await requireActiveAdmin(request);
    const { uid, active } = request.data;
    if (typeof uid !== "string" || uid.length === 0 || typeof active !== "boolean") {
      throw new HttpsError("invalid-argument", "A user and account status are required.");
    }
    if (uid === adminUid && !active) {
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
      actorUid: adminUid,
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
