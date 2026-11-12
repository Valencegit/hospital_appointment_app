"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendAppointmentReminders = exports.setUserAccountStatus = exports.createStaffUser = exports.assignUserRole = exports.ensurePatientRole = exports.createAdminUser = exports.processBookingRequest = exports.assignPatientId = exports.bookAppointment = void 0;
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
// Patient ID generation
//
// Called automatically when a new document is created in the `patients/`
// collection. Assigns a sequential HMS-PAT-XXXXXX hospital ID using a
// Firestore counter transaction so IDs are always unique and monotonic.
//
// The ID is written back to both `patients/{uid}.patientId` and
// `users/{uid}.patientId` so both collections stay in sync.
// ─────────────────────────────────────────────────────────────────────────────
exports.assignPatientId = (0, firestore_1.onDocumentCreated)("patients/{uid}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const uid = event.params.uid;
    const data = snap.data();
    // Skip if a Patient ID was already assigned (re-triggered doc)
    if (typeof data.patientId === "string" && data.patientId.startsWith("HMS-PAT-")) {
        return;
    }
    const db = admin.firestore();
    const counterRef = db.collection("counters").doc("patients");
    const patientRef = db.collection("patients").doc(uid);
    const userRef = db.collection("users").doc(uid);
    let patientId = "";
    await db.runTransaction(async (tx) => {
        var _a, _b;
        const counter = await tx.get(counterRef);
        const lastNumber = counter.exists
            ? ((_b = (_a = counter.data()) === null || _a === void 0 ? void 0 : _a.lastNumber) !== null && _b !== void 0 ? _b : 0)
            : 0;
        const nextNumber = lastNumber + 1;
        patientId = `HMS-PAT-${String(nextNumber).padStart(6, "0")}`;
        tx.set(counterRef, { lastNumber: nextNumber }, { merge: true });
        tx.update(patientRef, { patientId });
    });
    // Mirror the ID onto the users document (best-effort, non-critical)
    try {
        await userRef.update({ patientId });
    }
    catch (_a) {
        // users/ document may not exist yet during early registration
    }
    console.log(`[assignPatientId] Assigned ${patientId} to patient ${uid}`);
});
// ─────────────────────────────────────────────────────────────────────────────
// Booking trigger: processes booking_requests documents transactionally
// ─────────────────────────────────────────────────────────────────────────────
exports.processBookingRequest = (0, firestore_1.onDocumentCreated)("booking_requests/{requestId}", async (event) => {
    var _a, _b;
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const requestId = event.params.requestId;
    const db = admin.firestore();
    const { patientId, slotId, departmentId, notes, } = data;
    const slotRef = db.collection("appointment_slots").doc(slotId);
    const requestRef = db.collection("booking_requests").doc(requestId);
    try {
        const patientDoc = await db.collection("users").doc(patientId).get();
        const patientData = patientDoc.data();
        if (!patientDoc.exists ||
            (patientData === null || patientData === void 0 ? void 0 : patientData.role) !== "patient" ||
            (patientData === null || patientData === void 0 ? void 0 : patientData.is_active) === false) {
            throw new Error("The patient account is not active.");
        }
        const patientName = (_b = (_a = patientData.full_name) !== null && _a !== void 0 ? _a : patientData.fullName) !== null && _b !== void 0 ? _b : "Patient";
        let appointmentId = "";
        let appointmentDepartmentName = "hospital";
        await db.runTransaction(async (transaction) => {
            var _a, _b, _c, _d, _e;
            const slotDoc = await transaction.get(slotRef);
            if (!slotDoc.exists)
                throw new Error("Slot not found.");
            const slotData = slotDoc.data();
            const bookedCount = (_a = slotData.bookedCount) !== null && _a !== void 0 ? _a : 0;
            const capacity = (_b = slotData.capacity) !== null && _b !== void 0 ? _b : 0;
            const isActive = (_c = slotData.isActive) !== null && _c !== void 0 ? _c : false;
            if (!isActive)
                throw new Error("This slot is no longer active.");
            if (slotData.departmentId !== departmentId) {
                throw new Error("The selected slot does not match the department.");
            }
            appointmentDepartmentName = (_d = slotData.departmentName) !== null && _d !== void 0 ? _d : "hospital";
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
                departmentName: (_e = slotData.departmentName) !== null && _e !== void 0 ? _e : "",
                doctorId: typeof slotData.doctorId === "string" ? slotData.doctorId : null,
                doctorName: typeof slotData.doctorName === "string" ? slotData.doctorName : null,
                appointmentDate: slotData.date,
                appointmentTime: slotData.startTime,
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
            body: `Your ${appointmentDepartmentName} appointment is pending confirmation.`,
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
    const bootstrapRef = db.collection("system_settings").doc("admin_bootstrap");
    await db.runTransaction(async (transaction) => {
        const bootstrap = await transaction.get(bootstrapRef);
        if (bootstrap.exists) {
            throw new https_1.HttpsError("failed-precondition", "Initial administrator setup is already complete or in progress.");
        }
        transaction.create(bootstrapRef, {
            email: email.trim().toLowerCase(),
            startedAt: now,
        });
    });
    let hasExistingAdmin;
    try {
        const existingAdmins = await db
            .collection("users")
            .where("role", "==", "admin")
            .where("is_active", "==", true)
            .limit(1)
            .get();
        hasExistingAdmin = !existingAdmins.empty;
    }
    catch (error) {
        try {
            await bootstrapRef.delete();
        }
        catch (cleanupError) {
            console.error("Could not release initial-admin setup lock:", cleanupError);
        }
        throw error;
    }
    if (hasExistingAdmin) {
        await bootstrapRef.delete();
        throw new https_1.HttpsError("failed-precondition", "Initial administrator setup is already complete.");
    }
    let userRecord;
    try {
        userRecord = await admin.auth().createUser(Object.assign({ email,
            password, displayName: fullName }, (phoneNumber ? { phoneNumber } : {})));
    }
    catch (error) {
        try {
            await bootstrapRef.delete();
        }
        catch (cleanupError) {
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
            phone_number: phoneNumber !== null && phoneNumber !== void 0 ? phoneNumber : "",
            role: "admin",
            is_active: true,
            created_at: now,
            updated_at: null,
        });
        batch.set(adminRef, {
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
        batch.set(auditRef, {
            actorUid: "system",
            action: "admin_account_created",
            recordRef: userRecord.uid,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        await batch.commit();
        await admin.auth().setCustomUserClaims(userRecord.uid, { role: "admin" });
    }
    catch (error) {
        try {
            const rollback = db.batch();
            rollback.delete(userRef);
            rollback.delete(adminRef);
            rollback.delete(auditRef);
            rollback.delete(bootstrapRef);
            await rollback.commit();
            await admin.auth().deleteUser(userRecord.uid);
        }
        catch (rollbackError) {
            console.error(`Could not roll back incomplete initial admin ${userRecord.uid}:`, rollbackError);
        }
        console.error("Could not provision initial admin:", error);
        throw new https_1.HttpsError("internal", "Initial administrator setup failed. Contact Firebase support if the account still exists.");
    }
    return {
        success: true,
        uid: userRecord.uid,
        message: `Admin account created for ${email}`,
    };
});
const assignedRoles = [
    "patient",
    "receptionist",
    "doctor",
    "scheduling_officer",
    "admin",
];
async function requireActiveAdmin(request) {
    const auth = request.auth;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in to continue.");
    }
    if (auth.token.role !== "admin") {
        throw new https_1.HttpsError("permission-denied", "Administrator access required.");
    }
    const adminDoc = await admin.firestore().collection("users").doc(auth.uid).get();
    const adminData = adminDoc.data();
    if (!adminDoc.exists ||
        (adminData === null || adminData === void 0 ? void 0 : adminData.role) !== "admin" ||
        (adminData === null || adminData === void 0 ? void 0 : adminData.is_active) === false) {
        throw new https_1.HttpsError("permission-denied", "An active administrator is required.");
    }
    return auth.uid;
}
exports.ensurePatientRole = (0, https_1.onCall)({ enforceAppCheck: false }, async (request) => {
    var _a;
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Sign in to continue.");
    }
    const userRef = admin.firestore().collection("users").doc(request.auth.uid);
    const userDoc = await userRef.get();
    const userData = userDoc.data();
    if (!userDoc.exists ||
        (userData === null || userData === void 0 ? void 0 : userData.role) !== "patient" ||
        (userData === null || userData === void 0 ? void 0 : userData.is_active) === false ||
        request.auth.token.role != null) {
        throw new https_1.HttpsError("permission-denied", "Only an active patient account can receive the patient role.");
    }
    await admin.auth().setCustomUserClaims(request.auth.uid, Object.assign(Object.assign({}, ((_a = (await admin.auth().getUser(request.auth.uid)).customClaims) !== null && _a !== void 0 ? _a : {})), { role: "patient" }));
    return { role: "patient" };
});
exports.assignUserRole = (0, https_1.onCall)({ enforceAppCheck: false }, async (request) => {
    var _a, _b, _c, _d, _e;
    const adminUid = await requireActiveAdmin(request);
    const { uid, role } = request.data;
    if (typeof uid !== "string" ||
        uid.length === 0 ||
        typeof role !== "string" ||
        !assignedRoles.includes(role)) {
        throw new https_1.HttpsError("invalid-argument", "A valid user and role are required.");
    }
    if (uid === adminUid) {
        throw new https_1.HttpsError("failed-precondition", "Administrators cannot change their own role.");
    }
    const auth = admin.auth();
    let target;
    try {
        target = await auth.getUser(uid);
    }
    catch (error) {
        if (typeof error === "object" &&
            error !== null &&
            "code" in error &&
            error.code === "auth/user-not-found") {
            throw new https_1.HttpsError("not-found", "User account not found.");
        }
        throw error;
    }
    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
        throw new https_1.HttpsError("not-found", "Hospital user profile not found.");
    }
    const existingRole = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
    const staffRef = db.collection("staff").doc(uid);
    if (role === "doctor" ||
        role === "receptionist" ||
        role === "scheduling_officer") {
        const staffDoc = await staffRef.get();
        const staffData = staffDoc.data();
        const employeeId = (_c = (_b = staffData === null || staffData === void 0 ? void 0 : staffData.employeeId) !== null && _b !== void 0 ? _b : staffData === null || staffData === void 0 ? void 0 : staffData.staffId) !== null && _c !== void 0 ? _c : staffData === null || staffData === void 0 ? void 0 : staffData.staff_id;
        const departmentId = (_d = staffData === null || staffData === void 0 ? void 0 : staffData.departmentId) !== null && _d !== void 0 ? _d : staffData === null || staffData === void 0 ? void 0 : staffData.department_id;
        if (!staffDoc.exists || !employeeId || !departmentId) {
            throw new https_1.HttpsError("failed-precondition", "Create the staff account with its staff ID and department before assigning this role.");
        }
    }
    if (existingRole === "admin" &&
        role !== "admin" &&
        (await db.collection("users")
            .where("role", "==", "admin")
            .where("is_active", "==", true)
            .get()).size <= 1) {
        throw new https_1.HttpsError("failed-precondition", "The last active administrator cannot be demoted.");
    }
    const batch = db.batch();
    batch.update(userRef, {
        role,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    if (role === "doctor" ||
        role === "receptionist" ||
        role === "scheduling_officer") {
        batch.update(staffRef, {
            staffRole: role,
            role,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    else if (role === "patient" || role === "admin") {
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
    await auth.setCustomUserClaims(uid, Object.assign(Object.assign({}, ((_e = target.customClaims) !== null && _e !== void 0 ? _e : {})), { role }));
    return { success: true, uid, role };
});
exports.createStaffUser = (0, https_1.onCall)({ enforceAppCheck: false }, async (request) => {
    var _a, _b;
    const adminUid = await requireActiveAdmin(request);
    const { fullName, email, phoneNumber, employeeId, departmentId, role, specialization, } = request.data;
    const normalizedEmail = typeof email === "string" ? email.trim().toLowerCase() : "";
    const normalizedName = typeof fullName === "string" ? fullName.trim() : "";
    const normalizedPhone = typeof phoneNumber === "string" ? phoneNumber.trim() : "";
    const normalizedEmployeeId = typeof employeeId === "string" ? employeeId.trim() : "";
    if (!normalizedName ||
        !normalizedEmail ||
        !normalizedPhone ||
        !normalizedEmployeeId ||
        typeof departmentId !== "string" ||
        !departmentId.trim() ||
        !["receptionist", "doctor", "scheduling_officer"].includes(role)) {
        throw new https_1.HttpsError("invalid-argument", "Name, email, phone, staff ID, department, and a valid staff role are required.");
    }
    if (role === "doctor" &&
        (typeof specialization !== "string" || !specialization.trim())) {
        throw new https_1.HttpsError("invalid-argument", "A specialization is required for doctor accounts.");
    }
    const db = admin.firestore();
    const departmentDoc = await db
        .collection("departments")
        .doc(departmentId.trim())
        .get();
    const department = departmentDoc.data();
    const departmentIsActive = (_b = (_a = department === null || department === void 0 ? void 0 : department.isActive) !== null && _a !== void 0 ? _a : department === null || department === void 0 ? void 0 : department.active_status) !== null && _b !== void 0 ? _b : true;
    if (!departmentDoc.exists || departmentIsActive !== true) {
        throw new https_1.HttpsError("failed-precondition", "Select an active department.");
    }
    const departmentName = typeof (department === null || department === void 0 ? void 0 : department.name) === "string" ? department.name : "";
    if (!departmentName) {
        throw new https_1.HttpsError("failed-precondition", "The department has no name.");
    }
    const duplicateEmployeeId = await db
        .collection("staff")
        .where("employeeId", "==", normalizedEmployeeId)
        .limit(1)
        .get();
    if (!duplicateEmployeeId.empty) {
        throw new https_1.HttpsError("already-exists", "That staff ID is already in use.");
    }
    const auth = admin.auth();
    let createdUser;
    try {
        createdUser = await auth.createUser({
            email: normalizedEmail,
            displayName: normalizedName,
            emailVerified: false,
        });
    }
    catch (error) {
        if (typeof error === "object" &&
            error !== null &&
            "code" in error &&
            error.code === "auth/email-already-exists") {
            throw new https_1.HttpsError("already-exists", "An account already uses this email.");
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
            specialization: role === "doctor" ? specialization.trim() : "",
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
    }
    catch (error) {
        try {
            const rollback = db.batch();
            rollback.delete(userRef);
            rollback.delete(staffRef);
            rollback.delete(auditRef);
            await rollback.commit();
            await auth.deleteUser(createdUser.uid);
        }
        catch (rollbackError) {
            console.error(`Could not roll back incomplete staff account ${createdUser.uid}:`, rollbackError);
        }
        console.error("Could not provision staff account:", error);
        throw new https_1.HttpsError("internal", "Staff account setup failed. Contact an administrator if the account still appears.");
    }
    return { success: true, uid: createdUser.uid, email: normalizedEmail, role };
});
exports.setUserAccountStatus = (0, https_1.onCall)({ enforceAppCheck: false }, async (request) => {
    var _a;
    const adminUid = await requireActiveAdmin(request);
    const { uid, active } = request.data;
    if (typeof uid !== "string" || uid.length === 0 || typeof active !== "boolean") {
        throw new https_1.HttpsError("invalid-argument", "A user and account status are required.");
    }
    if (uid === adminUid && !active) {
        throw new https_1.HttpsError("failed-precondition", "Administrators cannot deactivate their own account.");
    }
    const db = admin.firestore();
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
        throw new https_1.HttpsError("not-found", "Hospital user profile not found.");
    }
    if (!active &&
        ((_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role) === "admin" &&
        (await db.collection("users")
            .where("role", "==", "admin")
            .where("is_active", "==", true)
            .get()).size <= 1) {
        throw new https_1.HttpsError("failed-precondition", "The last active administrator cannot be deactivated.");
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