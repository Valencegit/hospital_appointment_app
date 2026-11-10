/// Comprehensive form validation utilities for clinical and authentication forms.
class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^\+?[0-9]{9,15}$',
  );

  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? email(String? value) => validateEmail(value);

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? password(String? value) => validatePassword(value);

  // Password Confirmation Validation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? confirmPassword(String? confirmPassword, String original) =>
      validateConfirmPassword(original, confirmPassword);

  // Name Validation
  static String? validateName(String? value, [String fieldName = 'Full name']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  static String? name(String? value, {String fieldName = 'Name'}) =>
      validateName(value, fieldName);

  // Phone Validation
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!_phoneRegExp.hasMatch(cleanPhone)) {
      return 'Enter a valid phone number (9-15 digits)';
    }
    return null;
  }

  static String? phone(String? value) => validatePhone(value);

  // General Required Validation
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) =>
      validateRequired(value, fieldName);

  // Date Validation
  static String? date(DateTime? value) {
    if (value == null) return 'Date is required.';
    return null;
  }
}
