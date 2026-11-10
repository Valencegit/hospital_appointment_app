import 'package:flutter_test/flutter_test.dart';
import 'package:appointmentapp/core/constants/app_constants.dart';
import 'package:appointmentapp/core/utils/validators.dart';

void main() {
  test('App metadata smoke test', () {
    expect(AppConstants.appName, 'Metro Health Hospital');
    expect(AppConstants.appVersion, '1.0.0');
    expect(AppConstants.colUsers, 'users');
    expect(AppConstants.colPatients, 'patients');
    expect(AppConstants.colStaff, 'staff');
  });

  test('Form validators smoke test', () {
    expect(Validators.validateEmail('test@hospital.com'), isNull);
    expect(Validators.validateEmail('invalid'), isNotNull);
    expect(Validators.validatePassword('123456'), isNull);
    expect(Validators.validatePassword('123'), isNotNull);
  });
}
