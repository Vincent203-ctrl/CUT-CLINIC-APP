import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/appointment.dart';

/// Opens the phone's / browser's calendar with the appointment pre-filled.
/// Uses a Google Calendar "add event" link, so it works on Chrome and on
/// Android (Google Calendar app) without extra permissions.
class CalendarService {
  /// The SRS gives no visit length, so the event is 30 minutes long.
  static const int visitMinutes = 30;

  static Future<bool> addToCalendar(Appointment a) async {
    final start = a.scheduledAt;
    if (start == null) return false;
    final end = start.add(const Duration(minutes: visitMinutes));

    final f = DateFormat("yyyyMMdd'T'HHmmss'Z'");
    final service = a.serviceName;
    final title = (service == null || service.isEmpty)
        ? 'CUT Clinic appointment'
        : 'CUT Clinic: $service';

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': title,
      'dates': '${f.format(start.toUtc())}/${f.format(end.toUtc())}',
      'details': 'Your CUT Clinic appointment has been approved. Please arrive on time.',
      'location': 'CUT Clinic, Central University of Technology, Free State',
    });

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}