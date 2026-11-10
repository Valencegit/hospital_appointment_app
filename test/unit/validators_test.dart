import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('Email validator accepts valid emails and rejects invalid formats', () {
      expect(Validators.validateEmail('doctor.smith@hospital.com'), isNull);
      expect(Validators.validateEmail('patient123@care.org'), isNull);
      expect(Validators.validateEmail('user@domain.co.uk'), isNull);

      expect(Validators.validateEmail(null), 'Email address is required');
      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail('   '), 'Email address is required');
      expect(Validators.validateEmail('notanemail'), 'Please enter a valid email address');
      expect(Validators.validateEmail('missing@domain'), 'Please enter a valid email address');
      expect(Validators.validateEmail('@nodomain.com'), 'Please enter a valid email address');
    });

    test('Password validator enforces minimum 6 characters', () {
      expect(Validators.validatePassword('secret123'), isNull);
      expect(Validators.validatePassword('123456'), isNull);

      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters long');
    });

    test('Confirm password validator verifies exact match', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
      expect(Validators.validateConfirmPassword('pass123', null), 'Please confirm your password');
      expect(Validators.validateConfirmPassword('pass123', ''), 'Please confirm your password');
      expect(Validators.validateConfirmPassword('pass123', 'different'), 'Passwords do not match');
    });

    test('Name validator enforces non-empty and minimum 2 characters', () {
      expect(Validators.validateName('Dr. John Doe'), isNull);
      expect(Validators.validateName('Al'), isNull);

      expect(Validators.validateName(null), 'Full name is required');
      expect(Validators.validateName(''), 'Full name is required');
      expect(Validators.validateName('A'), 'Full name must be at least 2 characters');
    });

    test('Phone validator verifies length and digit patterns', () {
      expect(Validators.validatePhone('+15551234567'), isNull);
      expect(Validators.validatePhone('0712345678'), isNull);
      expect(Validators.validatePhone('(555) 123-4567'), isNull);

      expect(Validators.validatePhone(null), 'Phone number is required');
      expect(Validators.validatePhone(''), 'Phone number is required');
      expect(Validators.validatePhone('1234'), 'Enter a valid phone number (9-15 digits)');
    });

    test('Required field validator detects missing values', () {
      expect(Validators.validateRequired('Cardiology', 'Department'), isNull);
      expect(Validators.validateRequired(null, 'Department'), 'Department is required');
      expect(Validators.validateRequired('', 'Department'), 'Department is required');
      expect(Validators.validateRequired('   ', 'Department'), 'Department is required');
    });
  });
}
