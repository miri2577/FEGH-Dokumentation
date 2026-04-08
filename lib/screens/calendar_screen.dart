import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;
import 'package:provider/provider.dart';
import '../models/appointment.dart' as app;
import '../models/arbeitszeit.dart';
import '../models/client.dart';
import '../providers/app_provider.dart';
import '../widgets/appointment_data_source.dart';
import 'create_appointment_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final sf.CalendarController _calendarController = sf.CalendarController();
  sf.CalendarView _currentView = sf.CalendarView.week;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _calendarController.view = _currentView;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _calendarController.dispose();
    super.dispose();
  }

  void _switchView(sf.CalendarView view) {
    setState(() {
      _currentView = view;
      _calendarController.view = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        elevation: 0,
        toolbarHeight: 44,
        actions: [
          _buildViewToggleButtons(),
          IconButton(
            icon: const Icon(Icons.palette, size: 20),
            onPressed: () => _showColorLegend(),
            tooltip: 'Klientenfarben',
          ),
          IconButton(
            icon: const Icon(Icons.today, size: 20),
            onPressed: () {
              _calendarController.displayDate = DateTime.now();
              _calendarController.selectedDate = DateTime.now();
            },
            tooltip: 'Heute',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final dataSource = AppointmentDataSource(appProvider.appointments, clients: appProvider.clients);
          return _buildCalendar(dataSource, appProvider);
        },
      ),
    );
  }

  Widget _buildViewToggleButtons() {
    final views = [
      (sf.CalendarView.month, Icons.calendar_view_month, 'Monat'),
      (sf.CalendarView.week, Icons.calendar_view_week, 'Woche'),
      (sf.CalendarView.workWeek, Icons.view_week, 'Arbeitswoche'),
      (sf.CalendarView.day, Icons.calendar_today, 'Tag'),
      (sf.CalendarView.schedule, Icons.view_agenda, 'Agenda'),
    ];

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ToggleButtons(
        isSelected: views.map((v) => v.$1 == _currentView).toList(),
        onPressed: (index) => _switchView(views[index].$1),
        borderRadius: BorderRadius.circular(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 30),
        children: views
            .map((v) => Tooltip(message: v.$3, child: Icon(v.$2, size: 18)))
            .toList(),
      ),
    );
  }

  Widget _buildCalendar(
      AppointmentDataSource dataSource, AppProvider appProvider) {
    final theme = Theme.of(context);

    return sf.SfCalendar(
      controller: _calendarController,
      view: _currentView,
      dataSource: dataSource,
      firstDayOfWeek: 1,
      // Drag & Drop + Resize wie Google Calendar
      allowDragAndDrop: true,
      allowAppointmentResize: true,
      // Navigation
      showNavigationArrow: true,
      showDatePickerButton: true,
      // Zeitraster: kompakt wie Google Calendar
      timeSlotViewSettings: sf.TimeSlotViewSettings(
        startHour: 6,
        endHour: 22,
        timeInterval: const Duration(minutes: 30),
        timeFormat: 'HH:mm',
        timeIntervalHeight: 40,
        timeTextStyle: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.outline,
        ),
        dayFormat: 'EEE',
        dateFormat: 'd',
      ),
      // Monatsansicht: kompakt, Termine als Indicator-Dots
      monthViewSettings: const sf.MonthViewSettings(
        appointmentDisplayMode: sf.MonthAppointmentDisplayMode.appointment,
        showAgenda: false,
        appointmentDisplayCount: 3,
        monthCellStyle: sf.MonthCellStyle(),
        navigationDirection: sf.MonthNavigationDirection.vertical,
      ),
      // Schedule-Ansicht
      scheduleViewSettings: sf.ScheduleViewSettings(
        appointmentItemHeight: 50,
        hideEmptyScheduleWeek: true,
        monthHeaderSettings: sf.MonthHeaderSettings(
          monthFormat: 'MMMM yyyy',
          height: 60,
          textAlign: TextAlign.center,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      // Header kompakt
      headerHeight: 40,
      headerStyle: sf.CalendarHeaderStyle(
        textAlign: TextAlign.center,
        textStyle: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      viewHeaderHeight: 50,
      viewHeaderStyle: sf.ViewHeaderStyle(
        dayTextStyle: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.w500,
        ),
        dateTextStyle: TextStyle(
          fontSize: 20,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
      ),
      todayHighlightColor: theme.colorScheme.primary,
      todayTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
      cellBorderColor: theme.dividerColor.withValues(alpha: 0.3),
      selectionDecoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      // Termine rendern
      appointmentBuilder: (context, details) {
        return _buildAppointmentWidget(details, appProvider);
      },
      // Klick auf leere Zelle → neuer Termin (wie Google Calendar)
      onTap: (details) => _onCalendarTap(details, appProvider),
      // Drag & Drop
      onDragEnd: (details) => _onDragEnd(details, appProvider),
      // Resize
      onAppointmentResizeEnd: (details) =>
          _onResizeEnd(details, appProvider),
    );
  }

  Color _clientColor(String clientId, AppProvider appProvider) {
    final client = appProvider.getClientById(clientId);
    return colorForClient(clientId, customColor: client?.customColor);
  }

  Widget _buildAppointmentWidget(
      sf.CalendarAppointmentDetails details, AppProvider appProvider) {
    final apt = details.appointments.first;

    app.Appointment? appointment;
    if (apt is app.Appointment) {
      appointment = apt;
    }
    if (appointment == null) return const SizedBox.shrink();

    final color = _clientColor(appointment.clientId, appProvider);
    final height = details.bounds.height;
    final isMonthView = _currentView == sf.CalendarView.month;

    // Monatsansicht: schmaler Balken
    if (isMonthView) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          '${_formatTime(appointment.startTime)} ${appointment.clientName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // Wochen-/Tagesansicht: Google-Calendar-Stil
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: HSLColor.fromColor(color)
                .withLightness(
                    (HSLColor.fromColor(color).lightness - 0.15).clamp(0, 1))
                .toColor(),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            appointment.clientName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: height > 35 ? 12 : 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (height > 28)
            Text(
              '${_formatTime(appointment.startTime)} – ${_formatTime(appointment.endTime)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: height > 35 ? 10 : 8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (height > 60 && appointment.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                appointment.notes,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // --- Interaktionen ---

  void _onCalendarTap(
      sf.CalendarTapDetails details, AppProvider appProvider) {
    // Klick auf Termin → Details anzeigen
    if (details.targetElement == sf.CalendarElement.appointment &&
        details.appointments != null &&
        details.appointments!.isNotEmpty) {
      final apt = details.appointments!.first;
      if (apt is app.Appointment) {
        final client = appProvider.getClientById(apt.clientId);
        _showAppointmentDetails(apt, client);
      }
      return;
    }

    // Klick auf leere Zelle → neuer Termin (wie Google Calendar)
    if (details.targetElement == sf.CalendarElement.calendarCell &&
        details.date != null) {
      final date = details.date!;

      // In Monatsansicht: nur Datum, kein Zeitslot
      if (_currentView == sf.CalendarView.month) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateAppointmentScreen(
              initialDate: DateTime(date.year, date.month, date.day),
            ),
          ),
        );
        return;
      }

      // In Wochen-/Tagesansicht: Datum + Zeitslot
      final startTime = TimeOfDay(hour: date.hour, minute: date.minute);
      final endMinutes = date.hour * 60 + date.minute + 60;
      final endTime = TimeOfDay(
        hour: (endMinutes ~/ 60).clamp(0, 23),
        minute: endMinutes % 60,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateAppointmentScreen(
            initialDate: DateTime(date.year, date.month, date.day),
            initialStartTime: startTime,
            initialEndTime: endTime,
          ),
        ),
      );
    }
  }

  void _onDragEnd(
      sf.AppointmentDragEndDetails details, AppProvider appProvider) {
    final apt = details.appointment;
    if (apt is! app.Appointment) return;

    final newStart = details.droppingTime;
    if (newStart == null) return;

    final duration = apt.endTime.difference(apt.startTime);
    final updated = apt.copyWith(
      startTime: newStart,
      endTime: newStart.add(duration),
      date: DateTime(newStart.year, newStart.month, newStart.day),
    );
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      appProvider.updateAppointment(updated);
    });
  }

  void _onResizeEnd(
      sf.AppointmentResizeEndDetails details, AppProvider appProvider) {
    final apt = details.appointment;
    if (apt is! app.Appointment) return;

    final newStart = details.startTime;
    final newEnd = details.endTime;
    if (newStart == null || newEnd == null) return;

    final updated = apt.copyWith(
      startTime: newStart,
      endTime: newEnd,
      date: DateTime(newStart.year, newStart.month, newStart.day),
    );
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      appProvider.updateAppointment(updated);
    });
  }

  // --- Action Handlers ---

  void _handleAppointmentAction(String action, app.Appointment appointment) {
    switch (action) {
      case 'edit':
        break;
      case 'worktime':
        _showWorkTimeDialog(appointment);
        break;
      case 'delete':
        _showDeleteConfirmation(appointment);
        break;
    }
  }

  void _showWorkTimeDialog(app.Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('In Arbeitszeit übernehmen'),
          content: Text(
            'Soll der Termin mit "${appointment.clientName}" in die Arbeitszeit übernommen werden?\n\n'
            'Datum: ${_formatDate(appointment.date)}\n'
            'Zeit: ${_formatTime(appointment.startTime)} - ${_formatTime(appointment.endTime)}\n'
            'Dauer: ${appointment.formattedDuration}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                _transferToWorkTime(appointment);
                Navigator.of(context).pop();
              },
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    );
  }

  void _transferToWorkTime(app.Appointment appointment) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final arbeitszeit = Arbeitszeit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      datum: appointment.date,
      startzeit: appointment.startTime,
      endzeit: appointment.endTime,
      taetigkeit: 'Betreuung - ${appointment.clientName}',
      notizen: appointment.notes,
      createdAt: DateTime.now(),
      clientId: appointment.clientId,
      appointmentId: appointment.id,
      typ: ArbeitszeitTyp.betreuung,
    );

    final success = await appProvider.addArbeitszeit(arbeitszeit);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Termin mit "${appointment.clientName}" wurde in Arbeitszeit übernommen'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Übernehmen in Arbeitszeit'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(app.Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termin löschen'),
          content: Text(
              'Möchten Sie den Termin mit "${appointment.clientName}" wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteAppointment(appointment);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAppointment(app.Appointment appointment) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final success = await appProvider.deleteAppointment(appointment.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Termin wurde gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Löschen des Termins'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAppointmentDetails(app.Appointment appointment, Client? client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorForClient(appointment.clientId, customColor: client?.customColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.clientName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatDate(appointment.date),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Aktions-Buttons im Header
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          Navigator.of(context).pop();
                          _handleAppointmentAction(value, appointment);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Bearbeiten'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'worktime',
                            child: ListTile(
                              leading: Icon(Icons.work_history),
                              title: Text('Zu Arbeitszeit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Löschen',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.access_time,
                    'Zeit',
                    '${_formatTime(appointment.startTime)} – ${_formatTime(appointment.endTime)} (${appointment.formattedDuration})',
                  ),
                  if (client != null) ...[
                    if (client.berufsgruppe != null)
                      _buildDetailRow(
                        Icons.work,
                        'Berufsgruppe',
                        client.berufsgruppe!,
                      ),
                    if (client.eingliederung != null)
                      _buildDetailRow(
                        Icons.support,
                        'Eingliederungshilfe',
                        client.eingliederung!,
                      ),
                  ],
                  if (appointment.fachleistungsstunden > 0)
                    _buildDetailRow(
                      Icons.schedule,
                      'Fachleistungsstunden',
                      '${appointment.fachleistungsstunden}h',
                    ),
                  if (appointment.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes,
                            color: Theme.of(context).colorScheme.outline,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notizen',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appointment.notes,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showWorkTimeDialog(appointment);
                          },
                          icon: const Icon(Icons.work_history, size: 18),
                          label: const Text('Zu Arbeitszeit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to edit
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Bearbeiten'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: Theme.of(context).colorScheme.outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showColorLegend() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Klientenfarben'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tippen Sie auf eine Farbe, um sie zu ändern:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: appProvider.clients.map((client) {
                            final color = colorForClient(client.id, customColor: client.customColor);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => _showColorPicker(client, appProvider, setDialogState),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.black26),
                                      ),
                                      child: const Icon(Icons.edit, size: 14, color: Colors.white70),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      client.vollstaendigerName,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  if (client.customColor != null)
                                    IconButton(
                                      icon: const Icon(Icons.refresh, size: 18),
                                      tooltip: 'Automatische Farbe',
                                      onPressed: () async {
                                        // customColor auf null setzen (Reset)
                                        final resetClient = Client(
                                          id: client.id,
                                          klientenId: client.klientenId,
                                          name: client.name,
                                          berufsgruppe: client.berufsgruppe,
                                          eingliederung: client.eingliederung,
                                          createdAt: client.createdAt,
                                          vorname: client.vorname,
                                          nachname: client.nachname,
                                          geburtsdatum: client.geburtsdatum,
                                          betreuungSeit: client.betreuungSeit,
                                          kostenuebernahme: client.kostenuebernahme,
                                          kostenuebernahmeVon: client.kostenuebernahmeVon,
                                          kostenuebernahmeBis: client.kostenuebernahmeBis,
                                          fachleistungsstunden: client.fachleistungsstunden,
                                          fachleistungsIntervall: client.fachleistungsIntervall,
                                          hilfeTyp: client.hilfeTyp,
                                          icfBereiche: client.icfBereiche,
                                          verbrauchteStunden: client.verbrauchteStunden,
                                          kalkulationsfaktorOverride: client.kalkulationsfaktorOverride,
                                          stundensatzOverride: client.stundensatzOverride,
                                          vertreter1Id: client.vertreter1Id,
                                          vertreter2Id: client.vertreter2Id,
                                          tibZiele: client.tibZiele,
                                          individuelleTibZiele: client.individuelleTibZiele,
                                          rechtsgrundlage: client.rechtsgrundlage,
                                          customColor: null,
                                        );
                                        await appProvider.updateClient(resetClient);
                                        setDialogState(() {});
                                        if (mounted) setState(() {});
                                      },
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    if (appProvider.clients.isEmpty)
                      const Text(
                        'Keine Klienten vorhanden',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Schließen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static const List<Color> _presetColors = [
    Color(0xFF1976D2), // Blau
    Color(0xFF388E3C), // Grün
    Color(0xFFD32F2F), // Rot
    Color(0xFF7B1FA2), // Lila
    Color(0xFFF57C00), // Orange
    Color(0xFF00796B), // Teal
    Color(0xFFC2185B), // Pink
    Color(0xFF455A64), // Blaugrau
    Color(0xFF5D4037), // Braun
    Color(0xFF303F9F), // Indigo
    Color(0xFF0097A7), // Cyan
    Color(0xFFAFB42B), // Lime
    Color(0xFFE64A19), // Dunkelorange
    Color(0xFF512DA8), // Dunkelviolett
    Color(0xFF00838F), // Dunkelcyan
    Color(0xFF689F38), // Hellgrün
  ];

  void _showColorPicker(Client client, AppProvider appProvider, void Function(void Function()) setDialogState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Farbe: ${client.vollstaendigerName}'),
          content: SizedBox(
            width: 280,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((color) {
                final isSelected = client.customColor == color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
                return InkWell(
                  onTap: () async {
                    final hexColor = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
                    final updated = client.copyWith(customColor: hexColor);
                    await appProvider.updateClient(updated);
                    setDialogState(() {});
                    if (mounted) setState(() {});
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : Border.all(color: Colors.black12),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  // --- Hilfsfunktionen ---

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
