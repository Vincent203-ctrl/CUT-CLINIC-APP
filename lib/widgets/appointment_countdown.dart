import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/brand.dart';
import '../models/appointment.dart';
import '../services/calendar_service.dart';
import 'common.dart';

/// "Your visit is in 2 days" countdown + Add to calendar button.
/// Shown for approved appointments that have an assigned date and time.
class AppointmentCountdown extends StatefulWidget {
  const AppointmentCountdown({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<AppointmentCountdown> createState() => _AppointmentCountdownState();
}

class _AppointmentCountdownState extends State<AppointmentCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // refresh the countdown while the screen is open
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _addToCalendar() async {
    showInfo(context, 'Opening your calendar...');
    final ok = await CalendarService.addToCalendar(widget.appointment);
    if (!ok && mounted) {
      showError(context, 'Could not open a calendar. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final at = widget.appointment.scheduledAt;
    if (at == null) return const SizedBox.shrink();

    final diff = at.difference(DateTime.now());
    // hide once the visit time is long gone but the status was not updated
    if (diff < const Duration(hours: -2)) return const SizedBox.shrink();

    final started = diff.inSeconds <= 0;
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CutColors.blueDark, Color(0xFF0B5CAD)],
        ),
        boxShadow: [
          BoxShadow(
            color: CutColors.blue.withAlpha(70),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                started ? "It's appointment time" : 'Your visit is in',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!started)
            Row(
              children: [
                Expanded(child: _Unit(value: days, label: 'DAYS')),
                const SizedBox(width: 8),
                Expanded(child: _Unit(value: hours, label: 'HOURS')),
                const SizedBox(width: 8),
                Expanded(child: _Unit(value: minutes, label: 'MIN')),
              ],
            )
          else
            const Text(
              'Please head to the clinic.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            '${DateFormat('EEEE, d MMMM').format(at)} at ${DateFormat('HH:mm').format(at)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Material(
              color: Colors.white,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _addToCalendar,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 18, color: CutColors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Add to calendar',
                        style: TextStyle(
                          color: CutColors.blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Unit extends StatelessWidget {
  const _Unit({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}