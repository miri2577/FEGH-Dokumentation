import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/teilhabeziel.dart';
import '../../models/zielmessung.dart';
import '../../models/pos_messung.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/wirkungsmessung_service.dart';
import '../../services/wirksamkeitsbericht_service.dart';
import '../../services/cloud_storage_adapter.dart';
import '../../widgets/wirkungsmessung/gas_rating_widget.dart';
import '../../widgets/wirkungsmessung/gas_verlauf_chart.dart';
import '../../widgets/wirkungsmessung/pos_netzdiagramm.dart';
import '../pdf_preview_screen.dart';
import 'ziel_liste_screen.dart';
import 'pos_uebersicht_screen.dart';

/// Wirkungs-Dashboard fuer einen Klienten - zeigt GAS-Verlaeufe und POS-Netzdiagramm.
class WirkungsDashboardScreen extends StatefulWidget {
  final Client client;
  final String bewertetVon;

  const WirkungsDashboardScreen({
    super.key,
    required this.client,
    required this.bewertetVon,
  });

  @override
  State<WirkungsDashboardScreen> createState() => _WirkungsDashboardScreenState();
}

class _WirkungsDashboardScreenState extends State<WirkungsDashboardScreen> {
  final _service = WirkungsmessungService();
  List<Teilhabeziel> _ziele = [];
  Map<String, List<Zielmessung>> _messungen = {};
  List<PosMessung> _posMessungen = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ziele = await _service.zieleFuerClient(widget.client.id);
    final messungenMap = <String, List<Zielmessung>>{};
    for (final z in ziele) {
      messungenMap[z.id] = await _service.messungenFuerZiel(z.id);
    }
    final pos = await _service.posMessungenFuerClient(widget.client.id);
    pos.sort((a, b) => a.messdatum.compareTo(b.messdatum));
    if (!mounted) return;
    setState(() {
      _ziele = ziele;
      _messungen = messungenMap;
      _posMessungen = pos;
      _loading = false;
    });
  }

  ({CloudStorageAdapter adapter, String remoteDir})? _cloudTarget() {
    final settings = context.read<AppProvider>().settings;
    final user = settings.hidriveUsername;
    final pass = settings.hidrivePassword;
    final org = settings.organizationId;
    final team = settings.teamId;
    if (user.isEmpty || pass.isEmpty || org.isEmpty) return null;

    // Wenn in Zukunft ein Provider-Typ in Settings ergaenzt wird, hier auslesen.
    // Solange nur HiDrive-Credentials gesetzt werden, nutzen wir den HiDrive-Adapter.
    const providerType = 'hidrive';
    final adapter = CloudStorageFactory.create(
      type: providerType,
      url: '',
      username: user,
      password: pass,
    );
    final subdir = team.isNotEmpty
        ? 'eingliederungshilfe/organizations/$org/teams/$team/wirkung'
        : 'eingliederungshilfe/organizations/$org/administration/wirkung';
    return (adapter: adapter, remoteDir: subdir);
  }

  Future<void> _syncToCloud() async {
    final target = _cloudTarget();
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud-Zugangsdaten fehlen')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final ok = await _service.syncToCloud(
      adapter: target.adapter,
      remoteDir: target.remoteDir,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Upload erfolgreich' : 'Upload fehlgeschlagen'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _syncFromCloud() async {
    final target = _cloudTarget();
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud-Zugangsdaten fehlen')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloud-Daten laden?'),
        content: const Text(
          'Lokale Wirkungsdaten werden durch die Cloud-Version ersetzt. '
          'Nicht synchronisierte lokale Aenderungen gehen verloren.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Herunterladen')),
        ],
      ),
    );
    if (confirm != true) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final ok = await _service.syncFromCloud(
      adapter: target.adapter,
      remoteDir: target.remoteDir,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (ok) await _load();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Download erfolgreich' : 'Download fehlgeschlagen'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _generateReport() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final service = WirksamkeitsberichtService();
      final bytes = await service.generateClientReport(
        client: widget.client,
        autor: widget.bewertetVon,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close loader
      final datumStr =
          '${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}';
      final filename =
          'Wirksamkeitsbericht_${widget.client.vollstaendigerName.replaceAll(' ', '_')}_$datumStr.pdf';
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            pdfBytes: bytes,
            title: 'Wirksamkeitsbericht',
            fileName: filename,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wirkungs-Dashboard'),
            Text(widget.client.vollstaendigerName, style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Cloud-Sync',
            icon: const Icon(Icons.cloud_sync),
            onSelected: (v) {
              if (v == 'up') _syncToCloud();
              if (v == 'down') _syncFromCloud();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'up',
                child: Row(children: [
                  Icon(Icons.cloud_upload, size: 18),
                  SizedBox(width: 8),
                  Text('Hochladen (lokal -> Cloud)'),
                ]),
              ),
              PopupMenuItem(
                value: 'down',
                child: Row(children: [
                  Icon(Icons.cloud_download, size: 18),
                  SizedBox(width: 8),
                  Text('Herunterladen (Cloud -> lokal)'),
                ]),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Wirksamkeitsbericht PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generateReport,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKpiSection(theme),
                  const SizedBox(height: 24),
                  _buildPosSection(theme),
                  const SizedBox(height: 24),
                  _buildGasSection(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── KPI / Quick Stats ─────────────────────────────────────────────

  Widget _buildKpiSection(ThemeData theme) {
    final aktiveZiele = _ziele.where((z) => z.status == TeilhabezielStatus.aktiv).length;
    final erreichteZiele = _ziele.where((z) => z.status == TeilhabezielStatus.erreicht).length;
    final allMessungen = _messungen.values.expand((e) => e).toList();
    final durchschnittGas = allMessungen.isEmpty
        ? null
        : allMessungen.fold<int>(0, (s, m) => s + m.bewertung.wert) / allMessungen.length;
    final letztePos = _posMessungen.isNotEmpty ? _posMessungen.last : null;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpi(theme, 'Aktive Ziele', '$aktiveZiele', Icons.flag, Colors.blue),
        _kpi(theme, 'Erreicht', '$erreichteZiele', Icons.check_circle, Colors.green),
        _kpi(
          theme,
          'GAS-Schnitt',
          durchschnittGas == null ? '-' : '${durchschnittGas >= 0 ? "+" : ""}${durchschnittGas.toStringAsFixed(1)}',
          Icons.trending_up,
          durchschnittGas == null
              ? Colors.grey
              : (durchschnittGas >= 0 ? Colors.green : Colors.orange),
        ),
        _kpi(
          theme,
          'POS gesamt',
          letztePos == null ? '-' : '${letztePos.gesamtProzent.toStringAsFixed(0)}%',
          Icons.assessment,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _kpi(ThemeData theme, String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  // ── POS ───────────────────────────────────────────────────────────

  Widget _buildPosSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Lebensqualitaet (POS)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PosUebersichtScreen(
                        client: widget.client,
                        bewertetVon: widget.bewertetVon,
                      ),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_posMessungen.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Noch keine POS-Messung',
                    style: TextStyle(color: theme.colorScheme.outline)),
              )
            else ...[
              Center(
                child: PosNetzdiagramm(
                  messung: _posMessungen.last,
                  vergleich: _posMessungen.length >= 2 ? _posMessungen.first : null,
                  size: 320,
                ),
              ),
              if (_posMessungen.length >= 2) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(theme.colorScheme.outline, 'Baseline'),
                    const SizedBox(width: 16),
                    _legendDot(theme.colorScheme.primary, 'Aktuell'),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _buildPosDifferenz(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPosDifferenz(ThemeData theme) {
    if (_posMessungen.length < 2) return const SizedBox.shrink();
    final first = _posMessungen.first;
    final last = _posMessungen.last;
    final diff = last.gesamtProzent - first.gesamtProzent;
    final color = diff > 0 ? Colors.green : (diff < 0 ? Colors.red : Colors.grey);
    final icon = diff > 0 ? Icons.trending_up : (diff < 0 ? Icons.trending_down : Icons.trending_flat);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Entwicklung: ${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)}% '
              '(${first.gesamtProzent.toStringAsFixed(0)}% → ${last.gesamtProzent.toStringAsFixed(0)}%)',
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── GAS Verlaeufe ─────────────────────────────────────────────────

  Widget _buildGasSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Teilhabeziele (GAS)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZielListeScreen(
                        client: widget.client,
                        bewertetVon: widget.bewertetVon,
                      ),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ziele.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Noch keine Teilhabeziele angelegt',
                    style: TextStyle(color: theme.colorScheme.outline)),
              )
            else
              ..._ziele.map((z) => _buildZielEintrag(theme, z)),
          ],
        ),
      ),
    );
  }

  Widget _buildZielEintrag(ThemeData theme, Teilhabeziel ziel) {
    final msgs = _messungen[ziel.id] ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ziel.titel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (msgs.isNotEmpty)
                GasRatingWidget(value: msgs.last.bewertung, kompakt: true, readOnly: true),
            ],
          ),
          const SizedBox(height: 4),
          Text('${ziel.kategorieDisplayName} - ${msgs.length} Messung${msgs.length == 1 ? "" : "en"}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          GasVerlaufChart(messungen: msgs, height: 160),
        ],
      ),
    );
  }
}
