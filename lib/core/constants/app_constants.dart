/// Application-wide constants including Firestore collections,
/// configuration keys, role names, and system labels.
class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Metro Health Hospital';
  static const String appTagline = 'Your Health, Our Priority';
  static const String appVersion = '1.0.0';

  // Firestore Collections (Short and Full conventions)
  static const String colUsers = 'users';
  static const String colPatients = 'patients';
  static const String colStaff = 'staff';
  static const String colAdmins = 'admins';
  static const String colDepartments = 'departments';
  static const String colAppointments = 'appointments';
  static const String colAppointmentSlots = 'appointment_slots';
  static const String colNotifications = 'notifications';

  static const String usersCollection = 'users';
  static const String patientsCollection = 'patients';
  static const String staffCollection = 'staff';
  static const String departmentsCollection = 'departments';
  static const String slotsCollection = 'appointment_slots';
  static const String appointmentsCollection = 'appointments';
  static const String notificationsCollection = 'notifications';
  static const String auditLogsCollection = 'audit_logs';

  // Role Strings
  static const String rolePatient = 'patient';
  static const String roleStaff = 'staff';
  static const String roleDoctor = 'doctor';
  static const String roleReceptionist = 'receptionist';
  static const String roleSchedulingOfficer = 'scheduling_officer';
  static const String roleAdmin = 'admin';

  // Appointment Statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCancelled = 'cancelled';
  static const String statusCompleted = 'completed';
  static const String statusNoShow = 'no_show';
  static const String statusCheckedIn = 'checked_in';
  static const String statusRescheduled = 'rescheduled';
  static const String statusCancelRequested = 'cancel_requested';
  static const String statusRescheduleRequested = 'reschedule_requested';

  // Local Storage (SharedPreferences) Keys
  static const String prefKeyThemeMode = 'theme_mode';
  static const String prefKeyUserRole = 'user_role';
  static const String prefKeyRememberMe = 'remember_me';
  static const String prefKeySavedEmail = 'saved_email';
  static const String prefUserRole = 'user_role';
  static const String prefUserId = 'user_id';

  // UI Durations & Metrics
  static const Duration splashDuration = Duration(milliseconds: 2200);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultBorderRadius = 12.0;
  static const double buttonHeight = 52.0;
  static const double textFieldHeight = 54.0;
  static const double defaultPadding = 16.0;
  static const int pageSize = 20;

  // Validation Rules
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int phoneLength = 10;

  // Error Messages
  static const String errGeneric =
      'An unexpected error occurred. Please try again.';
  static const String errNetwork =
      'Network connectivity issue. Please check your connection.';
  static const String errAuthFailed =
      'Authentication failed. Please verify your credentials.';
  static const String errUserNotFound =
      'No user account found with this email.';
  static const String errWrongPassword = 'Incorrect password provided.';
  static const String errEmailInUse =
      'An account already exists with this email address.';
  static const String errWeakPassword =
      'Password is too weak. Please use at least 6 characters.';
  static const String errInvalidEmail = 'Please provide a valid email address.';
}
