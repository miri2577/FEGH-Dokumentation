import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/arbeitszeit.dart';
import '../models/fahrweg.dart';
import '../providers/app_provider.dart';
import '../widgets/fahrweg_input_widget.dart';
import '../utils/responsive_utils.dart';
import '../widgets/dashboard_card.dart';
import 'freizeit_antrag_screen.dart';

class WorkTimeScreen extends StatefulWidget {
  const WorkTimeScreen({super.key});

  @override
  State<WorkTimeScreen> createState() => _WorkTimeScreenState();
}

class _WorkTimeScreenState extends State<WorkTimeScreen> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Arbeitszeit'),
            actions: [
              IconButton(
                icon: const Icon(Icons.event_available),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FreizeitAntragScreen(),
                    ),
                  );
                },
                tooltip: 'Freizeit beantragen',
              ),
              IconButton(
                icon: const Icon(Icons.list),
                onPressed: _showAllEntries,
                tooltip: 'Alle Einträge',
              ),
              IconButton(
                icon: const Icon(Icons.calendar_view_week),
                onPressed: _showWeeklyOverview,
                tooltip: 'Wochenübersicht',
              ),
            ],
          ),
          body: _buildResponsiveLayout(appProvider),
          floatingActionButton: FloatingActionButton(
            heroTag: "worktime_fab",
            onPressed: _showAddWorkTimeDialog,
            tooltip: 'Arbeitszeit erfassen',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveLayout(AppProvider appProvider) {
    if (ResponsiveUtils.isMobile(context)) {
      return _buildMobileLayout(appProvider);
    } else if (ResponsiveUtils.isTablet(context)) {
      return _buildTabletLayout(appProvider);
    } else {
      return _buildDesktopLayout(appProvider);
    }
  }

  Widget _buildMobileLayout(AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Monatsauswahl und Letzte Einträge untereinander
          _buildMonthSelector(),
          const SizedBox(height: 16),
          _buildRecentEntries(),
          const SizedBox(height: 24),
          // Cards: Datum Überstunden Tag Woche nebeneinander
          _buildWorkTimeStats(appProvider),
          const SizedBox(height: 24),
          _buildFahrwegeStats(appProvider),
          const SizedBox(height: 24),
          _buildYearlyOverview(appProvider),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Monatsauswahl und Letzte Einträge untereinander
          _buildMonthSelector(),
          const SizedBox(height: 20),
          _buildRecentEntries(),
          const SizedBox(height: 24),
          // Cards: Datum Überstunden Tag Woche nebeneinander
          _buildWorkTimeStats(appProvider),
          const SizedBox(height: 24),
          _buildFahrwegeStats(appProvider),
          const SizedBox(height: 24),
          _buildYearlyOverview(appProvider),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Monatsauswahl und Letzte Einträge untereinander
          _buildMonthSelector(),
          const SizedBox(height: 24),
          _buildRecentEntries(),
          const SizedBox(height: 32),
          // Cards: Datum Überstunden Tag Woche nebeneinander
          _buildWorkTimeStats(appProvider),
          const SizedBox(height: 32),
          _buildFahrwegeStats(appProvider),
          const SizedBox(height: 32),
          _buildYearlyOverview(appProvider),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monatsauswahl',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectMonth(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'de_DE').format(_selectedMonth),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Vorheriger Monat',
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _goToCurrentMonth(),
                    child: const Text(
                      'Heute',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Nächster Monat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyOverview(AppProvider appProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Jahresübersicht ${_selectedMonth.year}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildYearlyChart(appProvider),
            const SizedBox(height: 20),
            _buildWorkStatistics(appProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyChart(AppProvider appProvider) {
    return Column(
      children: [
        // Jan-Jun
        Container(
          height: 180,
          child: Row(
            children: List.generate(6, (index) {
              final month = DateTime(_selectedMonth.year, index + 1);
              final monthWorkHours = _getMonthWorkHours(appProvider, month);
              final maxHours = 200.0; // Angenommene Max-Stunden für Skalierung
              final height = (monthWorkHours / maxHours * 140).clamp(4.0, 140.0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: '${DateFormat('MMM', 'de_DE').format(month)}: ${monthWorkHours.toStringAsFixed(1)}h',
                        child: Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: _getMonthColor(monthWorkHours),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM', 'de_DE').format(month),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Jul-Dez
        Container(
          height: 180,
          child: Row(
            children: List.generate(6, (index) {
              final month = DateTime(_selectedMonth.year, index + 7);
              final monthWorkHours = _getMonthWorkHours(appProvider, month);
              final maxHours = 200.0; // Angenommene Max-Stunden für Skalierung
              final height = (monthWorkHours / maxHours * 140).clamp(4.0, 140.0);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: '${DateFormat('MMM', 'de_DE').format(month)}: ${monthWorkHours.toStringAsFixed(1)}h',
                        child: Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: _getMonthColor(monthWorkHours),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM', 'de_DE').format(month),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkStatistics(AppProvider appProvider) {
    final currentYear = _selectedMonth.year;
    final yearWorkHours = _getYearWorkHours(appProvider, currentYear);
    final avgMonthlyHours = yearWorkHours / 12;
    final expectedYearlyHours = appProvider.settings.wochenarbeitszeit * 52;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Gesamt ${currentYear}',
                '${yearWorkHours.toStringAsFixed(1)}h',
                Icons.work_history,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Ø pro Monat',
                '${avgMonthlyHours.toStringAsFixed(1)}h',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Soll ${currentYear}',
                '${expectedYearlyHours.toStringAsFixed(0)}h',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Differenz',
                '${(yearWorkHours - expectedYearlyHours).toStringAsFixed(1)}h',
                Icons.compare_arrows,
                yearWorkHours >= expectedYearlyHours ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legende:',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildLegendItem(Colors.green, 'Normal (<180h)'),
              _buildLegendItem(Colors.orange, 'Überdurchschnittlich'),
              _buildLegendItem(Colors.red, 'Viele Überstunden'),
              _buildLegendItem(Colors.grey, 'Wenig gearbeitet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkTimeStats(AppProvider appProvider) {
    // Arbeitszeiten für den ausgewählten Monat berechnen
    final selectedMonthHours = _getMonthWorkHours(appProvider, _selectedMonth);
    final expectedMonthlyHours = appProvider.settings.wochenarbeitszeit * 4.33; // ~4.33 Wochen pro Monat
    final overtimeThisMonth = selectedMonthHours - expectedMonthlyHours;

    // Arbeitszeiten für die Woche des ausgewählten Monats
    final selectedMonthWeekStart = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final selectedMonthWeekEnd = selectedMonthWeekStart.add(const Duration(days: 6));
    final weekHoursInSelectedMonth = _getDateRangeWorkHours(appProvider, selectedMonthWeekStart, selectedMonthWeekEnd);

    final isCurrentMonth = _selectedMonth.year == DateTime.now().year &&
                          _selectedMonth.month == DateTime.now().month;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: isCurrentMonth ? 'Heute' : 'Tagesschnitt',
                value: isCurrentMonth
                    ? appProvider.formatHours(appProvider.hoursWorkedToday)
                    : appProvider.formatHours(selectedMonthHours / DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day),
                icon: Icons.schedule,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardCard(
                title: isCurrentMonth ? 'Diese Woche' : 'Erste Woche',
                value: isCurrentMonth
                    ? appProvider.formatHours(appProvider.hoursWorkedThisWeek)
                    : appProvider.formatHours(weekHoursInSelectedMonth),
                icon: Icons.calendar_view_week,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: DateFormat('MMMM yyyy', 'de_DE').format(_selectedMonth),
                value: appProvider.formatHours(selectedMonthHours),
                icon: Icons.calendar_month,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DashboardCard(
                title: isCurrentMonth ? 'Überstunden' : 'Differenz',
                value: appProvider.formatOvertimeHours(overtimeThisMonth),
                icon: Icons.trending_up,
                color: overtimeThisMonth >= 0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFahrwegeStats(AppProvider appProvider) {
    if (appProvider.totalFahrwege == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Fahrwege',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Heute',
                    value: '${appProvider.kmDrivenToday.toStringAsFixed(1)} km',
                    icon: Icons.today,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: 'Diese Woche',
                    value: '${appProvider.kmDrivenThisWeek.toStringAsFixed(1)} km',
                    icon: Icons.calendar_view_week,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Dieser Monat',
                    value: '${appProvider.kmDrivenThisMonth.toStringAsFixed(1)} km',
                    icon: Icons.calendar_month,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DashboardCard(
                    title: 'Gesamt',
                    value: '${appProvider.totalKmDriven.toStringAsFixed(1)} km',
                    icon: Icons.route,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            if (appProvider.haeufigsteStrecken.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Häufigste Strecken',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...appProvider.haeufigsteStrecken.take(5).map((strecke) {
                final start = appProvider.getStandortById(strecke.startStandortId);
                final ziel = appProvider.getStandortById(strecke.zielStandortId);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.arrow_forward, size: 18),
                  title: Text('${start?.name ?? '?'} → ${ziel?.name ?? '?'}'),
                  trailing: Text(
                    '${strecke.distanzKm.toStringAsFixed(1)} km (${strecke.nutzungsAnzahl}x)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final recentArbeitszeiten = appProvider.arbeitszeiten
            .take(5)
            .toList()
          ..sort((a, b) => b.datum.compareTo(a.datum));
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Letzte Einträge',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAllEntries,
                      icon: const Icon(Icons.list),
                      label: const Text('Alle'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (recentArbeitszeiten.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Noch keine Arbeitszeiten erfasst',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Erfassen Sie Ihre ersten Arbeitszeiten',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentArbeitszeiten.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final arbeitszeit = recentArbeitszeiten[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getTypeColor(arbeitszeit.typ),
                          ),
                          child: Icon(
                            _getTypeIcon(arbeitszeit.typ),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(arbeitszeit.taetigkeit),
                        subtitle: Text(
                          '${arbeitszeit.formatierteStartzeit} - ${arbeitszeit.formatierteEndzeit} (${arbeitszeit.formatierteArbeitszeit})'
                        ),
                        trailing: Text(
                          arbeitszeit.formatiertesDatum,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getTypeColor(ArbeitszeitTyp typ) {
    switch (typ) {
      case ArbeitszeitTyp.betreuung:
        return Colors.blue;
      case ArbeitszeitTyp.buero:
        return Colors.green;
      case ArbeitszeitTyp.fahrt:
        return Colors.orange;
      case ArbeitszeitTyp.dokumentation:
        return Colors.purple;
      case ArbeitszeitTyp.verwaltung:
        return Colors.teal;
      case ArbeitszeitTyp.fortbildung:
        return Colors.indigo;
      case ArbeitszeitTyp.teambesprechung:
        return Colors.brown;
      case ArbeitszeitTyp.sonstige:
        return Colors.grey;
    }
  }
  
  IconData _getTypeIcon(ArbeitszeitTyp typ) {
    switch (typ) {
      case ArbeitszeitTyp.betreuung:
        return Icons.people;
      case ArbeitszeitTyp.buero:
        return Icons.business;
      case ArbeitszeitTyp.fahrt:
        return Icons.directions_car;
      case ArbeitszeitTyp.dokumentation:
        return Icons.description;
      case ArbeitszeitTyp.verwaltung:
        return Icons.admin_panel_settings;
      case ArbeitszeitTyp.fortbildung:
        return Icons.school;
      case ArbeitszeitTyp.teambesprechung:
        return Icons.group;
      case ArbeitszeitTyp.sonstige:
        return Icons.more_horiz;
    }
  }

  // Month selector methods
  void _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + months);
    });
  }

  void _goToCurrentMonth() {
    setState(() {
      _selectedMonth = DateTime.now();
    });
  }

  // Statistics calculation methods
  double _getMonthWorkHours(AppProvider appProvider, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    final monthEntries = appProvider.arbeitszeiten.where((entry) =>
        entry.datum.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        entry.datum.isBefore(endOfMonth.add(const Duration(days: 1)))
    );
    return monthEntries.fold(0.0, (sum, entry) => sum + entry.arbeitszeit.inMinutes / 60.0);
  }

  double _getYearWorkHours(AppProvider appProvider, int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    
    final yearEntries = appProvider.arbeitszeiten.where((entry) =>
        entry.datum.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
        entry.datum.isBefore(endOfYear.add(const Duration(days: 1)))
    );
    return yearEntries.fold(0.0, (sum, entry) => sum + entry.arbeitszeit.inMinutes / 60.0);
  }

  Color _getMonthColor(double hours) {
    if (hours < 120) return Colors.grey; // Wenig gearbeitet
    if (hours < 180) return Colors.green; // Normal
    if (hours < 220) return Colors.orange; // Überdurchschnittlich
    return Colors.red; // Viele Überstunden
  }

  double _getDateRangeWorkHours(AppProvider appProvider, DateTime start, DateTime end) {
    final entries = appProvider.arbeitszeiten.where((entry) =>
        entry.datum.isAfter(start.subtract(const Duration(days: 1))) &&
        entry.datum.isBefore(end.add(const Duration(days: 1)))
    );
    return entries.fold(0.0, (sum, entry) => sum + entry.arbeitszeit.inMinutes / 60.0);
  }

  void _showAddWorkTimeDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddWorkTimeScreen(),
      ),
    );
  }

  void _showWeeklyOverview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wochenübersicht wird implementiert...'),
      ),
    );
  }

  void _showAllEntries() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkTimeEntriesScreen(),
      ),
    );
  }
}

class WorkTimeEntriesScreen extends StatefulWidget {
  const WorkTimeEntriesScreen({super.key});

  @override
  State<WorkTimeEntriesScreen> createState() => _WorkTimeEntriesScreenState();
}

class _WorkTimeEntriesScreenState extends State<WorkTimeEntriesScreen> {
  void _showAddWorkTimeDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddWorkTimeScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alle Arbeitszeiten'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final arbeitszeiten = appProvider.arbeitszeiten;
          
          if (arbeitszeiten.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Keine Arbeitszeiten erfasst',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Erfassen Sie Ihre ersten Arbeitszeiten',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Sort by date, newest first
          final sortedArbeitszeiten = List<Arbeitszeit>.from(arbeitszeiten);
          sortedArbeitszeiten.sort((a, b) => b.datum.compareTo(a.datum));
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedArbeitszeiten.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final arbeitszeit = sortedArbeitszeiten[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getTypeColor(arbeitszeit.typ),
                    ),
                    child: Icon(
                      _getTypeIcon(arbeitszeit.typ),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(arbeitszeit.taetigkeit),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(arbeitszeit.formatiertesDatum),
                      Text('${arbeitszeit.formatierteStartzeit} - ${arbeitszeit.formatierteEndzeit}'),
                      Text('Dauer: ${arbeitszeit.formatierteArbeitszeit}'),
                      if (arbeitszeit.notizen.isNotEmpty)
                        Text(
                          arbeitszeit.notizen,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editArbeitszeit(arbeitszeit);
                          break;
                        case 'delete':
                          _deleteArbeitszeit(arbeitszeit);
                          break;
                      }
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
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Löschen'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "worktime_entries_fab",
        onPressed: _showAddWorkTimeDialog,
        tooltip: 'Arbeitszeit hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Color _getTypeColor(ArbeitszeitTyp typ) {
    switch (typ) {
      case ArbeitszeitTyp.betreuung:
        return Colors.blue;
      case ArbeitszeitTyp.buero:
        return Colors.green;
      case ArbeitszeitTyp.fahrt:
        return Colors.orange;
      case ArbeitszeitTyp.dokumentation:
        return Colors.purple;
      case ArbeitszeitTyp.verwaltung:
        return Colors.teal;
      case ArbeitszeitTyp.fortbildung:
        return Colors.indigo;
      case ArbeitszeitTyp.teambesprechung:
        return Colors.brown;
      case ArbeitszeitTyp.sonstige:
        return Colors.grey;
    }
  }
  
  IconData _getTypeIcon(ArbeitszeitTyp typ) {
    switch (typ) {
      case ArbeitszeitTyp.betreuung:
        return Icons.people;
      case ArbeitszeitTyp.buero:
        return Icons.business;
      case ArbeitszeitTyp.fahrt:
        return Icons.directions_car;
      case ArbeitszeitTyp.dokumentation:
        return Icons.description;
      case ArbeitszeitTyp.verwaltung:
        return Icons.admin_panel_settings;
      case ArbeitszeitTyp.fortbildung:
        return Icons.school;
      case ArbeitszeitTyp.teambesprechung:
        return Icons.group;
      case ArbeitszeitTyp.sonstige:
        return Icons.more_horiz;
    }
  }
  
  void _editArbeitszeit(Arbeitszeit arbeitszeit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditWorkTimeScreen(arbeitszeit: arbeitszeit),
      ),
    );
  }
  
  void _deleteArbeitszeit(Arbeitszeit arbeitszeit) {
    final parentContext = context;
    final appProvider = Provider.of<AppProvider>(parentContext, listen: false);
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arbeitszeit löschen'),
        content: Text(
          'Möchten Sie die Arbeitszeit "${arbeitszeit.taetigkeit}" vom ${arbeitszeit.formatiertesDatum} wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              final success = await appProvider.deleteArbeitszeit(arbeitszeit.id);

              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                        ? 'Arbeitszeit erfolgreich gelöscht'
                        : 'Fehler beim Löschen der Arbeitszeit',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

class EditWorkTimeScreen extends StatefulWidget {
  final Arbeitszeit arbeitszeit;
  
  const EditWorkTimeScreen({super.key, required this.arbeitszeit});

  @override
  State<EditWorkTimeScreen> createState() => _EditWorkTimeScreenState();
}

class _EditWorkTimeScreenState extends State<EditWorkTimeScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late ArbeitszeitTyp _selectedTyp;
  late TextEditingController _descriptionController;
  String? _selectedClientId;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.arbeitszeit.datum;
    _startTime = TimeOfDay.fromDateTime(widget.arbeitszeit.startzeit);
    _endTime = TimeOfDay.fromDateTime(widget.arbeitszeit.endzeit);
    _selectedTyp = widget.arbeitszeit.typ;
    _descriptionController = TextEditingController(text: widget.arbeitszeit.notizen);
    _selectedClientId = widget.arbeitszeit.clientId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbeitszeit bearbeiten'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Datum'),
              subtitle: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Startzeit'),
              subtitle: Text(_startTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (time != null) {
                  setState(() {
                    _startTime = time;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Endzeit'),
              subtitle: Text(_endTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (time != null) {
                  setState(() {
                    _endTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ArbeitszeitTyp>(
              value: _selectedTyp,
              decoration: const InputDecoration(
                labelText: 'Art der Tätigkeit',
                border: OutlineInputBorder(),
              ),
              items: ArbeitszeitTyp.values.map((typ) {
                return DropdownMenuItem(
                  value: typ,
                  child: Text(typ.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTyp = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                final clients = appProvider.clients;
                return DropdownButtonFormField<String?>(
                  value: _selectedClientId,
                  decoration: const InputDecoration(
                    labelText: 'Klient zuordnen (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Kein Klient'),
                    ),
                    ...clients.map((client) {
                      final idPrefix = client.klientenId != null ? '${client.klientenId} - ' : '';
                      return DropdownMenuItem<String?>(
                        value: client.id,
                        child: Text('$idPrefix${client.vollstaendigerName}'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() async {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    
    // Validation
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endzeit muss nach der Startzeit liegen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final updatedArbeitszeit = widget.arbeitszeit.copyWith(
      datum: _selectedDate,
      startzeit: startDateTime,
      endzeit: endDateTime,
      taetigkeit: _selectedTyp.displayName,
      notizen: _descriptionController.text,
      typ: _selectedTyp,
      clientId: _selectedClientId,
    );
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final success = await appProvider.updateArbeitszeit(updatedArbeitszeit);
    
    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arbeitszeit erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Aktualisieren der Arbeitszeit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class AddWorkTimeScreen extends StatefulWidget {
  const AddWorkTimeScreen({super.key});

  @override
  State<AddWorkTimeScreen> createState() => _AddWorkTimeScreenState();
}

class _AddWorkTimeScreenState extends State<AddWorkTimeScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();
  ArbeitszeitTyp _selectedTyp = ArbeitszeitTyp.betreuung;
  String? _selectedClientId;
  final _descriptionController = TextEditingController();
  FahrwegData? _fahrwegHin;
  FahrwegData? _fahrwegRueck;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arbeitszeit hinzufügen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveWorkTime,
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arbeitszeit erfassen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Datum'),
                      subtitle: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Von'),
                      subtitle: Text(_startTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (time != null) {
                          setState(() {
                            _startTime = time;
                          });
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Bis'),
                      subtitle: Text(_endTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (time != null) {
                          setState(() {
                            _endTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ArbeitszeitTyp>(
                      value: _selectedTyp,
                      decoration: const InputDecoration(
                        labelText: 'Art der Tätigkeit',
                        border: OutlineInputBorder(),
                      ),
                      items: ArbeitszeitTyp.values.map((typ) {
                        return DropdownMenuItem(
                          value: typ,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getTypeColor(typ),
                                ),
                                child: Icon(
                                  _getTypeIcon(typ),
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(typ.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedTyp = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<AppProvider>(
                      builder: (context, appProvider, child) {
                        final clients = appProvider.clients;
                        return DropdownButtonFormField<String?>(
                          value: _selectedClientId,
                          decoration: const InputDecoration(
                            labelText: 'Klient zuordnen (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Kein Klient'),
                            ),
                            ...clients.map((client) {
                              final idPrefix = client.klientenId != null ? '${client.klientenId} - ' : '';
                              return DropdownMenuItem<String?>(
                                value: client.id,
                                child: Text('$idPrefix${client.vollstaendigerName}'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedClientId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Kurze Inhaltsbeschreibung (optional)',
                        border: OutlineInputBorder(),
                        helperText: 'z.B. Bürozeiten, Fahrt zum Klienten, etc.',
                      ),
                      maxLines: 3,
                    ),
                    if (_selectedTyp == ArbeitszeitTyp.fahrt) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Fahrweg',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      FahrwegInputWidget(
                        preSelectedClientId: _selectedClientId,
                        onFahrwegChanged: (hinfahrt, rueckfahrt) {
                          setState(() {
                            _fahrwegHin = hinfahrt;
                            _fahrwegRueck = rueckfahrt;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveWorkTime,
                icon: const Icon(Icons.save),
                label: const Text('Arbeitszeit speichern'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getTypeColor(ArbeitszeitTyp typ) {
    switch (typ) {
      case ArbeitszeitTyp.betreuung:
        return Colors.blue;
      case ArbeitszeitTyp.buero:
        return Colors.green;
      case ArbeitszeitTyp.fahrt:
        return Colors.orange;
      case ArbeitszeitTyp.dokumentation:
        return Colors.purple;
      case ArbeitszeitTyp.verwaltung:
        return Colors.teal;
      case ArbeitszeitTyp.fortbildung:
        return Colors.indigo;
      case ArbeitszeitTyp.teambesprechung:
        return Colors.brown;
      case ArbeitszeitTyp.sonstige:
        return Colors.grey;
    }
  }
  
  IconData _getTypeIcon(ArbeitszeitTyp typ) {
    switch (typ) {
      case ArbeitszeitTyp.betreuung:
        return Icons.people;
      case ArbeitszeitTyp.buero:
        return Icons.business;
      case ArbeitszeitTyp.fahrt:
        return Icons.directions_car;
      case ArbeitszeitTyp.dokumentation:
        return Icons.description;
      case ArbeitszeitTyp.verwaltung:
        return Icons.admin_panel_settings;
      case ArbeitszeitTyp.fortbildung:
        return Icons.school;
      case ArbeitszeitTyp.teambesprechung:
        return Icons.group;
      case ArbeitszeitTyp.sonstige:
        return Icons.more_horiz;
    }
  }
  
  void _saveWorkTime() async {
    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    
    // Validation
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Endzeit muss nach der Startzeit liegen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final arbeitszeit = Arbeitszeit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      datum: _selectedDate,
      startzeit: startDateTime,
      endzeit: endDateTime,
      taetigkeit: _selectedTyp.displayName,
      notizen: _descriptionController.text,
      createdAt: DateTime.now(),
      typ: _selectedTyp,
      clientId: _selectedClientId,
    );

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final success = await appProvider.addArbeitszeit(arbeitszeit);

    // Fahrwege speichern wenn Typ=Fahrt
    if (success && _selectedTyp == ArbeitszeitTyp.fahrt && _fahrwegHin != null) {
      final hinFahrweg = Fahrweg.create(
        datum: _selectedDate,
        startStandortId: _fahrwegHin!.startStandortId,
        startStandortName: _fahrwegHin!.startStandortName,
        zielStandortId: _fahrwegHin!.zielStandortId,
        zielStandortName: _fahrwegHin!.zielStandortName,
        distanzKm: _fahrwegHin!.distanzKm,
        clientId: _fahrwegHin!.clientId,
      );
      await appProvider.addFahrweg(hinFahrweg);

      if (_fahrwegRueck != null) {
        final rueckFahrweg = Fahrweg.create(
          datum: _selectedDate,
          startStandortId: _fahrwegRueck!.startStandortId,
          startStandortName: _fahrwegRueck!.startStandortName,
          zielStandortId: _fahrwegRueck!.zielStandortId,
          zielStandortName: _fahrwegRueck!.zielStandortName,
          distanzKm: _fahrwegRueck!.distanzKm,
          clientId: _fahrwegRueck!.clientId,
        );
        await appProvider.addFahrweg(rueckFahrweg);
      }
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arbeitszeit erfolgreich gespeichert'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Speichern der Arbeitszeit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}