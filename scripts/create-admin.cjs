/**
 * create-admin.cjs
 * ─────────────────────────────────────────────────────────────────────────────
 * One-time script to provision the first MediCare administrator account.
 *
 * HOW TO RUN:
 *   1. Install the Firebase Admin SDK locally (once):
 *        npm install firebase-admin --prefix scripts
 *
 *   2. Download a service-account key from:
 *        Firebase Console → Project Settings → Service accounts → Generate key
 *      Save it as:  scripts/serviceAccountKey.json
 *      Add serviceAccountKey.json to .gitignore (NEVER commit it).
 *
 *   3. Run:
 *        ADMIN_EMAIL="admin@yourhospital.com" \
 *        ADMIN_PASSWORD="YourStr0ngPassw0rd!" \
 *        ADMIN_NAME="System Administrator" \
 *        node scripts/create-admin.cjs
 *
 * This script is SAFE to re-run — it checks for an existing email first
 * and only creates the account if it does not already exist.
 *
 * IMPORTANT:
 *   • Use a strong password (12+ characters, mixed case, numbers, symbols).
 *   • Change the password immediately after first login via the app.
 *   • Delete or restrict this file from version control after initial setup.
 */

'use strict';

const path = require('path');
const admin = require(path.join(__dirname, 'node_modules', 'firebase-admin'));

// ── Load service account ───────────────────────────────────────────────────
const keyPath = path.join(__dirname, 'serviceAccountKey.json');
let serviceAccount;
try {
  serviceAccount = require(keyPath);
} catch {
  console.error(
    '\n❌  Service account key not found at:\n   ' + keyPath +
    '\n\n   Download it from Firebase Console → Project Settings → Service accounts\n'
  );
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// ── Read credentials from environment ─────────────────────────────────────
const email    = (process.env.ADMIN_EMAIL    || '').trim();
const password = (process.env.ADMIN_PASSWORD || '').trim();
const fullName = (process.env.ADMIN_NAME     || 'System Administrator').trim();

if (!email) {
  console.error('\n❌  Set ADMIN_EMAIL environment variable.\n');
  process.exit(1);
}
if (!password || password.length < 12) {
  console.error(
    '\n❌  Set ADMIN_PASSWORD to a string of at least 12 characters.\n'
  );
  process.exit(1);
}

// ── Provision the admin account ────────────────────────────────────────────
async function createAdmin() {
  const auth = admin.auth();
  const db   = admin.firestore();

  // Check for existing account
  let existingUid;
  try {
    const existing = await auth.getUserByEmail(email);
    existingUid = existing.uid;
    console.log(`\n⚠️   Firebase Auth account already exists for ${email}`);
    console.log(`    UID: ${existingUid}`);
  } catch (err) {
    if (err.code !== 'auth/user-not-found') throw err;
  }

  let uid;
  if (existingUid) {
    uid = existingUid;
    // Ensure the custom claim is set even if the user already existed
    await auth.setCustomUserClaims(uid, { role: 'admin' });
    console.log('    Custom claim role=admin set on existing account.');
  } else {
    // Create a new Firebase Auth account
    const userRecord = await auth.createUser({
      email,
      password,
      displayName: fullName,
      emailVerified: true,
      disabled: false,
    });
    uid = userRecord.uid;
    console.log(`\n✅  Firebase Auth account created.`);
    console.log(`    UID:   ${uid}`);
    console.log(`    Email: ${email}`);

    // Assign the trusted admin role claim
    await auth.setCustomUserClaims(uid, { role: 'admin' });
    console.log('    Custom claim role=admin assigned.');
  }

  // Write / update the Firestore profile
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection('users').doc(uid).set(
    {
      uid,
      full_name:    fullName,
      email:        email,
      phone_number: '',
      role:         'admin',
      is_active:    true,
      created_at:   now,
      updated_at:   now,
    },
    { merge: true }
  );
  console.log('    Firestore users/ document written.');

  // Write / update the admins/ profile
  await db.collection('admins').doc(uid).set(
    {
      uid,
      full_name:   fullName,
      email:       email,
      department:  'Hospital Administration',
      permissions: [
        'manage_users',
        'manage_staff',
        'manage_departments',
        'manage_slots',
        'view_analytics',
        'system_configuration',
      ],
      created_at: now,
      updated_at: now,
    },
    { merge: true }
  );
  console.log('    Firestore admins/ document written.');

  // Seed the patient ID counter if it doesn't exist yet
  const counterRef = db.collection('counters').doc('patients');
  const counterDoc = await counterRef.get();
  if (!counterDoc.exists) {
    await counterRef.set({ lastNumber: 0 });
    console.log('    Patient ID counter initialized (counters/patients).');
  }

  console.log(
    '\n🎉  Admin account ready.\n' +
    `    Email:    ${email}\n` +
    `    Password: (as set in ADMIN_PASSWORD)\n` +
    '    Open the app, sign in with these credentials,\n' +
    '    and you will be taken directly to the Admin Dashboard.\n'
  );
}

createAdmin().catch((err) => {
  console.error('\n❌  Unexpected error:', err.message || err);
  process.exit(1);
});
