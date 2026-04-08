import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;
import '../models/appointment.dart' as app;
import '../models/client.dart';

/// Deterministische Farbe basierend auf Client-ID (stabil unabhaengig von Sortierung)
Color colorForClient(String clientId, {String? customColor}) {
  if (customColor != null && customColor.isNotEmpty) {
    try {
      return Color(int.parse(customColor, radix: 16));
    } catch (_) {
      // Fallback auf automatische Farbe
    }
  }
  final hue = (clientId.hashCode.abs() * 137.508) % 360;
  return HSLColor.fromAHSL(1.0, hue, 0.55, 0.52).toColor();
}

class AppointmentDataSource extends sf.CalendarDataSource<app.Appointment> {
  final Map<String, String?> _clientColors;

  AppointmentDataSource(List<app.Appointment> appointments, {List<Client>? clients})
      : _clientColors = {
          if (clients != null)
            for (final c in clients) c.id: c.customColor,
        } {
    this.appointments = appointments;
  }

  @override
  DateTime getStartTime(int index) {
    final apt = appointments![index] as app.Appointment;
    return apt.startTime;
  }

  @override
  DateTime getEndTime(int index) {
    final apt = appointments![index] as app.Appointment;
    return apt.endTime;
  }

  @override
  String getSubject(int index) {
    final apt = appointments![index] as app.Appointment;
    return apt.clientName;
  }

  @override
  Color getColor(int index) {
    final apt = appointments![index] as app.Appointment;
    return colorForClient(apt.clientId, customColor: _clientColors[apt.clientId]);
  }

  @override
  String? getNotes(int index) {
    final apt = appointments![index] as app.Appointment;
    return apt.notes.isNotEmpty ? apt.notes : null;
  }

  @override
  app.Appointment? convertAppointmentToObject(
      app.Appointment? customData, sf.Appointment appointment) {
    return customData;
  }
}
