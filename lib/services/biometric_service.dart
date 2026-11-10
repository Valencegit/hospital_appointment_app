import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const _enabledPreference = 'biometric_login_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    final supported = await _auth.isDeviceSupported();
    final available = await _auth.canCheckBiometrics;
    return supported && available;
  }

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledPreference) ?? false;
  }

  Future<bool> enable() async {
    if (!await authenticate()) return false;
    final preferences = await SharedPreferences.getInstance();
    return preferences.setBool(_enabledPreference, true);
  }

  Future<void> disable() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_enabledPreference);
  }

  Future<bool> authenticate() async {
    try {
      if (!await canUseBiometrics()) return false;

      return await _auth.authenticate(
        localizedReason: 'Verify your identity to access your hospital account',
      );
    } catch (error) {
      debugPrint('Biometric authentication failed: $error');
      return false;
    }
  }
}
