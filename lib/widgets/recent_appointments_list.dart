import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';

class RecentAppointmentsList extends StatelessWidget {
  final List<Appointment> appointments;

  const RecentAppointmentsList({
    super.key,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: appointments.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            title: Text(
              appointment.clientName,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy • HH:mm').format(appointment.date),
                  overflow: TextOverflow.ellipsis,
                ),
                if (appointment.berufsgruppe.isNotEmpty)
                  Text(
                    appointment.berufsgruppe,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Icon(
              appointment.notes.isNotEmpty || appointment.recordedText.isNotEmpty
                  ? Icons.description
                  : Icons.description_outlined,
              color: appointment.notes.isNotEmpty || appointment.recordedText.isNotEmpty
                  ? Colors.green
                  : Colors.grey,
            ),
            onTap: () {
              // TODO: Navigate to appointment detail
            },
          );
        },
      ),
    );
  }
}