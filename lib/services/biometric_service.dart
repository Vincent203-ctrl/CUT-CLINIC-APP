import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BiometricSupport { web, unsupported, available }

class BiometricResult {
  const BiometricResult(this.ok, [this.message]);

  final bool ok;
  final String? message;
}

/// Fingerprint / face / phone-PIN unlock for the app. The password is never
/// stored: the Supabase session stays on the phone and this only guards it.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True once the student has unlocked (or just logged in) during this run.
  static bool unlockedThisRun = false;

  /// web: not possible in a browser. unsupported: the phone has no screen lock
  /// or biometrics. available: fingerprint, face or phone PIN can be used.
  static Future<BiometricSupport> support() async {
    if (kIsWeb) return BiometricSupport.web;
    try {
      final ok = await _auth.isDeviceSupported();
      return ok ? BiometricSupport.available : BiometricSupport.unsupported;
    } catch (_) {
      return BiometricSupport.unsupported;
    }
  }

  static Future<bool> isAvailable() async =>
      (await support()) == BiometricSupport.available;

  /// True when a fingerprint or face is actually enrolled on the phone.
  static Future<bool> hasBiometrics() async {
    if (kIsWeb) return false;
    try {
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String _key(String userId) => 'biometric_enabled_$userId';

  static Future<bool> isEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId)) ?? false;
  }

  static Future<void> setEnabled(String userId, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId), value);
  }

  /// Shows the system prompt (the phone PIN is allowed as a fallback).
  static Future<BiometricResult> authenticate({
    String reason = 'Unlock CUT Clinic',
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return BiometricResult(ok, ok ? null : 'Not recognised. Please try again.');
    } on PlatformException catch (e) {
      return BiometricResult(false, _friendly(e.code));
    } catch (_) {
      return const BiometricResult(
          false, 'Fingerprint unlock is not available in this version of the app.');
    }
  }

  static String _friendly(String code) {
    final c = code.toLowerCase();
    if (c.contains('fragment')) {
      return 'App setup incomplete: MainActivity must extend FlutterFragmentActivity.';
    }
    if (c.contains('passcodenotset')) {
      return 'Set a screen lock (PIN, pattern or password) in your phone settings first.';
    }
    if (c.contains('notenrolled')) {
      return 'No fingerprint or face is set up on this phone. Add one in Settings.';
    }
    if (c.contains('permanentlylockedout')) {
      return 'Biometrics are locked. Unlock your phone with its PIN, then try again.';
    }
    if (c.contains('lockedout')) {
      return 'Too many attempts. Please wait 30 seconds and try again.';
    }
    if (c.contains('notavailable')) {
      return 'Fingerprint or face is not available on this device.';
    }
    return 'Could not confirm your identity ($code).';
  }
}