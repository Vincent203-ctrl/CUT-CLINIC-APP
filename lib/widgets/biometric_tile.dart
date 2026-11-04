import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/brand.dart';
import '../services/biometric_service.dart';
import 'common.dart';

/// Profile switch: "Fingerprint / face unlock". Always shown; when the device
/// (or the web) cannot do it, the switch is disabled and says why.
class BiometricTile extends StatefulWidget {
  const BiometricTile({super.key});

  @override
  State<BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends State<BiometricTile> {
  BiometricSupport? _support;
  bool _hasBiometrics = false;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = Supabase.instance.client.auth.currentUser;
    final support = await BiometricService.support();
    final hasBio = await BiometricService.hasBiometrics();
    final enabled = (support == BiometricSupport.available && user != null)
        ? await BiometricService.isEnabled(user.id)
        : false;
    if (mounted) {
      setState(() {
        _support = support;
        _hasBiometrics = hasBio;
        _enabled = enabled;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      if (value) {
        final r = await BiometricService.authenticate(
          reason: 'Confirm to turn on fingerprint / face unlock',
        );
        if (!r.ok) {
          if (mounted) {
            showError(context, r.message ?? 'Could not confirm your identity.');
          }
          return;
        }
      }
      await BiometricService.setEnabled(user.id, value);
      BiometricService.unlockedThisRun = true; // do not lock straight away
      if (mounted) {
        setState(() => _enabled = value);
        showInfo(context,
            value ? 'Fingerprint / face unlock is on.' : 'Fingerprint / face unlock is off.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _subtitle {
    switch (_support) {
      case null:
        return 'Checking this device...';
      case BiometricSupport.web:
        return 'Available in the Android app only (not in a web browser).';
      case BiometricSupport.unsupported:
        return 'Set a screen lock or fingerprint in your phone settings to use this.';
      case BiometricSupport.available:
        return _hasBiometrics
            ? 'Ask for your fingerprint or face when you open the app'
            : 'Uses your phone PIN or pattern (no fingerprint set up yet)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final usable = _support == BiometricSupport.available;
    return Column(
      children: [
        const Divider(),
        SwitchListTile(
          secondary: Icon(Icons.fingerprint,
              color: usable ? CutColors.blue : Colors.grey),
          title: const Text('Fingerprint / face unlock',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(_subtitle),
          value: usable && _enabled,
          onChanged: (usable && !_busy) ? _toggle : null,
        ),
      ],
    );
  }
}