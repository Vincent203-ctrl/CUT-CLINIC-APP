import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/brand.dart';
import '../../services/biometric_service.dart';
import '../../services/clinic_service.dart';
import '../../widgets/cut_logo.dart';

/// Wraps the student area. If the student turned on fingerprint/face unlock,
/// the app asks for it when it opens and after being in the background for
/// more than a minute. A fresh password login never asks twice.
class BiometricGate extends StatefulWidget {
  const BiometricGate({super.key, required this.child});

  final Widget child;

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> with WidgetsBindingObserver {
  bool _checking = true;
  bool _locked = false;
  bool _prompting = false;
  String? _message;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final away = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away > const Duration(seconds: 60)) {
        BiometricService.unlockedThisRun = false;
        _evaluate();
      }
    }
  }

  Future<void> _evaluate() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || BiometricService.unlockedThisRun) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final enabled = await BiometricService.isEnabled(user.id);
    final available = enabled && await BiometricService.isAvailable();

    // a password login in the last 2 minutes counts as already unlocked
    final last = DateTime.tryParse(user.lastSignInAt ?? '');
    final fresh = last != null &&
        DateTime.now().toUtc().difference(last.toUtc()) < const Duration(minutes: 2);

    if (!available || fresh) {
      BiometricService.unlockedThisRun = true;
      if (mounted) {
        setState(() {
          _checking = false;
          _locked = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _checking = false;
        _locked = true;
        _message = null;
      });
    }
    _unlock();
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    _prompting = true;
    final result = await BiometricService.authenticate();
    _prompting = false;
    if (result.ok) {
      BiometricService.unlockedThisRun = true;
      if (mounted) setState(() => _locked = false);
    } else if (mounted) {
      setState(() => _message = result.message);
    }
  }

  Future<void> _usePassword() async {
    BiometricService.unlockedThisRun = false;
    await ClinicService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_locked) {
      return _LockScreen(
        message: _message,
        onUnlock: _unlock,
        onUsePassword: _usePassword,
      );
    }
    return widget.child;
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.message,
    required this.onUnlock,
    required this.onUsePassword,
  });

  final String? message;
  final VoidCallback onUnlock;
  final VoidCallback onUsePassword;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CutColors.blueDark, CutColors.blue],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const CutLogoBadge(size: 96),
                const SizedBox(height: 22),
                Text('CUT Clinic',
                    style: t.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Locked', style: t.bodyLarge?.copyWith(color: Colors.white70)),
                const Spacer(),
                Material(
                  color: Colors.white.withAlpha(30),
                  shape: const CircleBorder(side: BorderSide(color: Colors.white24)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onUnlock,
                    child: const SizedBox(
                      height: 112,
                      width: 112,
                      child: Icon(Icons.fingerprint, size: 64, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Tap to unlock with fingerprint, face or phone PIN',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: Colors.white70)),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: t.bodyMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
                const Spacer(flex: 2),
                TextButton(
                  onPressed: onUsePassword,
                  child: const Text('Use password instead',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}