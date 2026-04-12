import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/arbeitszeit.dart';
import '../../models/freizeit_antrag.dart';
import '../../models/mitarbeiter.dart';
import '../../providers/app_provider.dart';
import '../../services/audit_logger.dart';

/// Admin-Uebersicht fuer Genehmigung von Arbeitszeiten und Antraegen.
/// Farbkodiert, nach Teams geordnet, mit Genehmigungs-Workflow.
class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genehmigungen'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.access_time), text: 'Arbeitszeiten'),
            Tab(icon: Icon(Icons.event_available), text: 'Antraege'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ArbeitszeitApprovalTab(),
          _AntraegeApprovalTab(),
        ],
      ),
    );
  }
}

// ── Arbeitszeit-Tab ─────────────────────────────────────────────

class _ArbeitszeitApprovalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final mitarbeiter = app.mitarbeiter;
    final arbeitszeiten = app.arbeitszeiten;

    // Nach Mitarbeiter gruppieren
    final grouped = <String, List<Arbeitszeit>>{};
    for (final az in arbeitszeiten) {
      final maId = az.mitarbeiterId ?? 'unbekannt';
      grouped.putIfAbsent(maId, () => []).add(az);
    }

    // Statistiken
    final eingereicht = arbeitszeiten.where((a) => a.genehmigungsStatus == ArbeitszeitStatus.eingereicht).length;
    final genehmigt = arbeitszeiten.where((a) => a.genehmigungsStatus == ArbeitszeitStatus.genehmigt).length;
    final abgelehnt = arbeitszeiten.where((a) => a.genehmigungsStatus == ArbeitszeitStatus.abgelehnt).length;

    return Column(
      children: [
        // Status-Leiste
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusChip(label: 'Offen', count: eingereicht, color: Colors.orange),
              _StatusChip(label: 'Genehmigt', count: genehmigt, color: Colors.green),
              _StatusChip(label: 'Abgelehnt', count: abgelehnt, color: Colors.red),
            ],
          ),
        ),
        Expanded(
          child: arbeitszeiten.isEmpty
              ? Center(child: Text('Keine Arbeitszeiten vorhanden',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final maId = grouped.keys.elementAt(index);
                    final entries = grouped[maId]!..sort((a, b) => b.datum.compareTo(a.datum));
                    final ma = mitarbeiter.where((m) => m.id == maId).firstOrNull;
                    final maName = ma?.vollstaendigerName ?? maId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(maName.isNotEmpty ? maName[0] : '?'),
                        ),
                        title: Text(maName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${entries.length} Eintraege · '
                            '${entries.where((e) => e.genehmigungsStatus == ArbeitszeitStatus.eingereicht).length} offen'),
                        children: entries.take(20).map((az) => _ArbeitszeitTile(
                          arbeitszeit: az,
                          onApprove: () => _approve(context, az),
                          onReject: () => _reject(context, az),
                        )).toList(),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _approve(BuildContext context, Arbeitszeit az) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final updated = az.copyWith(
      genehmigungsStatus: ArbeitszeitStatus.genehmigt,
      genehmigungsDatum: DateTime.now(),
      genehmigtVon: app.settings.userName,
    );
    app.updateArbeitszeit(updated);
    AuditLogger.instance.log(
      action: 'arbeitszeit.genehmigt',
      userId: app.settings.userName,
      context: {'azId': az.id, 'mitarbeiter': az.mitarbeiterId},
    );
  }

  void _reject(BuildContext context, Arbeitszeit az) {
    final notizController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arbeitszeit ablehnen'),
        content: TextField(
          controller: notizController,
          decoration: const InputDecoration(
            labelText: 'Begruendung',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final app = Provider.of<AppProvider>(context, listen: false);
              final updated = az.copyWith(
                genehmigungsStatus: ArbeitszeitStatus.abgelehnt,
                genehmigungsDatum: DateTime.now(),
                genehmigungsNotiz: notizController.text,
                genehmigtVon: app.settings.userName,
              );
              app.updateArbeitszeit(updated);
              AuditLogger.instance.log(
                action: 'arbeitszeit.abgelehnt',
                userId: app.settings.userName,
                context: {'azId': az.id, 'grund': notizController.text},
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }
}

class _ArbeitszeitTile extends StatelessWidget {
  final Arbeitszeit arbeitszeit;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ArbeitszeitTile({
    required this.arbeitszeit,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final az = arbeitszeit;
    final statusColor = Arbeitszeit.statusColor(az.genehmigungsStatus);
    final statusName = Arbeitszeit.statusName(az.genehmigungsStatus);

    return ListTile(
      dense: true,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Row(
        children: [
          Text(az.formatiertesDatum, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('${az.formatierteStartzeit} - ${az.formatierteEndzeit}'),
          const SizedBox(width: 8),
          Text('(${az.formatierteArbeitszeit})', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(child: Text('${az.typ.displayName}: ${az.taetigkeit}')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(statusName,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ],
      ),
      trailing: az.genehmigungsStatus == ArbeitszeitStatus.eingereicht
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: 'Genehmigen',
                  onPressed: onApprove,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: 'Ablehnen',
                  onPressed: onReject,
                ),
              ],
            )
          : null,
    );
  }
}

// ── Antraege-Tab ─────────────────────────────────────────────────

class _AntraegeApprovalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final antraege = app.freizeitAntraege;

    final beantragt = antraege.where((a) => a.status == AntragStatus.beantragt).toList();
    final genehmigt = antraege.where((a) => a.status == AntragStatus.genehmigt).toList();
    final abgelehnt = antraege.where((a) => a.status == AntragStatus.abgelehnt).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusChip(label: 'Offen', count: beantragt.length, color: Colors.orange),
              _StatusChip(label: 'Genehmigt', count: genehmigt.length, color: Colors.green),
              _StatusChip(label: 'Abgelehnt', count: abgelehnt.length, color: Colors.red),
            ],
          ),
        ),
        Expanded(
          child: antraege.isEmpty
              ? Center(child: Text('Keine Antraege vorhanden',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: antraege.length,
                  itemBuilder: (context, index) {
                    final antrag = antraege[index];
                    return _AntragCard(
                      antrag: antrag,
                      mitarbeiterName: _getMitarbeiterName(app, antrag.mitarbeiterId),
                      onApprove: antrag.status == AntragStatus.beantragt
                          ? () => _approveAntrag(context, antrag) : null,
                      onReject: antrag.status == AntragStatus.beantragt
                          ? () => _rejectAntrag(context, antrag) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getMitarbeiterName(AppProvider app, String maId) {
    final ma = app.mitarbeiter.where((m) => m.id == maId).firstOrNull;
    return ma?.vollstaendigerName ?? maId;
  }

  void _approveAntrag(BuildContext context, FreizeitAntrag antrag) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final updated = antrag.copyWith(
      status: AntragStatus.genehmigt,
      genehmigungsDatum: DateTime.now(),
      genehmigungsNotiz: 'Genehmigt von ${app.settings.userName}',
    );
    app.updateFreizeitAntrag(updated);
    AuditLogger.instance.log(
      action: 'antrag.genehmigt',
      userId: app.settings.userName,
      context: {'antragId': antrag.id, 'typ': antrag.typ.name},
    );
  }

  void _rejectAntrag(BuildContext context, FreizeitAntrag antrag) {
    final notizController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Antrag ablehnen'),
        content: TextField(
          controller: notizController,
          decoration: const InputDecoration(
            labelText: 'Begruendung',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final app = Provider.of<AppProvider>(context, listen: false);
              final updated = antrag.copyWith(
                status: AntragStatus.abgelehnt,
                genehmigungsDatum: DateTime.now(),
                genehmigungsNotiz: notizController.text,
              );
              app.updateFreizeitAntrag(updated);
              AuditLogger.instance.log(
                action: 'antrag.abgelehnt',
                userId: app.settings.userName,
                context: {'antragId': antrag.id, 'grund': notizController.text},
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ablehnen'),
          ),
        ],
      ),
    );
  }
}

class _AntragCard extends StatelessWidget {
  final FreizeitAntrag antrag;
  final String mitarbeiterName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AntragCard({
    required this.antrag,
    required this.mitarbeiterName,
    this.onApprove,
    this.onReject,
  });

  Color get _statusColor {
    switch (antrag.status) {
      case AntragStatus.beantragt: return Colors.orange;
      case AntragStatus.genehmigt: return Colors.green;
      case AntragStatus.abgelehnt: return Colors.red;
      case AntragStatus.zurueckgezogen: return Colors.grey;
    }
  }

  Color get _typColor {
    switch (antrag.typ) {
      case FreizeitTyp.urlaub: return Colors.blue;
      case FreizeitTyp.freizeitausgleich: return Colors.teal;
      case FreizeitTyp.sonderurlaub: return Colors.purple;
      case FreizeitTyp.fortbildung: return Colors.indigo;
      case FreizeitTyp.krankmeldung: return Colors.red;
      case FreizeitTyp.unbezahlt: return Colors.grey;
    }
  }

  String get _typName {
    switch (antrag.typ) {
      case FreizeitTyp.urlaub: return 'Urlaub';
      case FreizeitTyp.freizeitausgleich: return 'Freizeitausgleich';
      case FreizeitTyp.sonderurlaub: return 'Sonderurlaub';
      case FreizeitTyp.fortbildung: return 'Fortbildung';
      case FreizeitTyp.krankmeldung: return 'Krankmeldung';
      case FreizeitTyp.unbezahlt: return 'Unbezahlter Urlaub';
    }
  }

  String get _statusName {
    switch (antrag.status) {
      case AntragStatus.beantragt: return 'Beantragt';
      case AntragStatus.genehmigt: return 'Genehmigt';
      case AntragStatus.abgelehnt: return 'Abgelehnt';
      case AntragStatus.zurueckgezogen: return 'Zurueckgezogen';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = antrag.bisDatum.difference(antrag.vonDatum).inDays + 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: _typColor, width: 4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _typColor.withValues(alpha: 0.2),
                    child: Text(mitarbeiterName.isNotEmpty ? mitarbeiterName[0] : '?',
                        style: TextStyle(color: _typColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mitarbeiterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_typName, style: TextStyle(color: _typColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(_statusName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text('${_formatDate(antrag.vonDatum)} - ${_formatDate(antrag.bisDatum)} ($days Tage)'),
                ],
              ),
              if (antrag.grund.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(antrag.grund, style: theme.textTheme.bodySmall),
              ],
              if (antrag.genehmigungsNotiz != null) ...[
                const SizedBox(height: 4),
                Text('Notiz: ${antrag.genehmigungsNotiz}',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
              if (onApprove != null || onReject != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReject != null)
                      OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Ablehnen', style: TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(width: 8),
                    if (onApprove != null)
                      FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Genehmigen'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text('$count', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
