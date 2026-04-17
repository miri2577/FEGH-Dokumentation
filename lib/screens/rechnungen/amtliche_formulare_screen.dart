import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/amtliches_formular.dart';
import '../../models/bundesland.dart';
import '../../providers/app_provider.dart';

/// Uebersicht aller amtlichen Formulare / Bedarfserhebungsinstrumente
/// pro Bundesland. Zeigt, welche Formulare ausfuellbar sind,
/// welche nur Blanko zur Verfuegung stehen und wo die offiziellen
/// Portale zu finden sind.
class AmtlicheFormulareScreen extends StatelessWidget {
  const AmtlicheFormulareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppProvider>().settings;
    final aktuellesLand = settings.bundesland;

    return Scaffold(
      appBar: AppBar(title: const Text('Amtliche Formulare')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoKarte(context),
          const SizedBox(height: 16),
          _buildLandSektion(context, aktuellesLand, istEigenes: true),
          const SizedBox(height: 24),
          ExpansionTile(
            initiallyExpanded: false,
            leading: const Icon(Icons.public),
            title: const Text('Andere Bundeslaender'),
            subtitle: const Text('Formulare und Portale deutschlandweit'),
            children: [
              for (final b in Bundesland.values)
                if (b != aktuellesLand)
                  _buildLandSektion(context, b, istEigenes: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoKarte(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text('Stand der Digitalisierung',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Aktuell ist nur das Berliner Formular 101 als ausfuellbares PDF '
              'verfuegbar. Die anderen Bundeslaender nutzen Webportale '
              '(PerSEH, ANLEI, Hamburg-Service...) oder statische PDFs. '
              'FEGH-Dokumentation bietet deshalb:\n\n'
              '• Fuer Berlin: direktes Ausfuellen des Formular 101\n'
              '• Fuer alle Laender: bundesweit nutzbarer Wirksamkeitsbericht '
              'nach §128 SGB IX (im Wirkungs-Dashboard)\n'
              '• Fuer alle Laender: Links zu den offiziellen Portalen und '
              'Blanko-Vorlagen zum Download',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandSektion(BuildContext context, Bundesland land,
      {required bool istEigenes}) {
    final profil = BundeslandProfile.forLand(land);
    final formulare = AmtlicheFormulareKatalog.fuerLand(land);

    return Padding(
      padding: EdgeInsets.only(bottom: istEigenes ? 0 : 12),
      child: Card(
        elevation: istEigenes ? 2 : 0,
        color: istEigenes
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(istEigenes ? Icons.location_on : Icons.map_outlined,
                      color: istEigenes
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  const SizedBox(width: 8),
                  Text(
                    profil.anzeigeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: istEigenes
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                  if (istEigenes) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Aktiv',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(profil.instrumentName,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              if (formulare.isEmpty)
                const Text(
                  'Keine Formular-Informationen hinterlegt.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                )
              else
                ...formulare.map((f) => _buildFormularKarte(context, f)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularKarte(BuildContext context, AmtlichesFormular f) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFuerArt(f.art), size: 20, color: _farbeFuerArt(f.art)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.titel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(f.kurzbeschreibung,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              _statusChip(f.art),
            ],
          ),
          const SizedBox(height: 8),
          Text(f.hinweise, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text('Stand: ${f.stand}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 11,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (f.assetPfad != null)
                OutlinedButton.icon(
                  onPressed: () => _exportBlanko(context, f),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Blanko-PDF speichern'),
                ),
              if (f.downloadUrl != null)
                OutlinedButton.icon(
                  onPressed: () => _openUrl(context, f.downloadUrl!),
                  icon: const Icon(Icons.cloud_download, size: 16),
                  label: const Text('Neueste Version online'),
                ),
              if (f.portalUrl != null)
                OutlinedButton.icon(
                  onPressed: () => _openUrl(context, f.portalUrl!),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Portal oeffnen'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFuerArt(EinreichungsArt a) {
    switch (a) {
      case EinreichungsArt.pdfAusfuellen: return Icons.edit_document;
      case EinreichungsArt.pdfBlanko: return Icons.description;
      case EinreichungsArt.webportal: return Icons.web;
      case EinreichungsArt.traegerportal: return Icons.account_balance;
    }
  }

  Color _farbeFuerArt(EinreichungsArt a) {
    switch (a) {
      case EinreichungsArt.pdfAusfuellen: return Colors.green;
      case EinreichungsArt.pdfBlanko: return Colors.orange;
      case EinreichungsArt.webportal: return Colors.blue;
      case EinreichungsArt.traegerportal: return Colors.purple;
    }
  }

  Widget _statusChip(EinreichungsArt a) {
    final (label, color) = switch (a) {
      EinreichungsArt.pdfAusfuellen => ('Ausfuellbar', Colors.green),
      EinreichungsArt.pdfBlanko => ('Blanko-PDF', Colors.orange),
      EinreichungsArt.webportal => ('Webportal', Colors.blue),
      EinreichungsArt.traegerportal => ('Traeger-Portal', Colors.purple),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) {
        await Clipboard.setData(ClipboardData(text: url));
        messenger.showSnackBar(
          const SnackBar(content: Text('Browser nicht verfuegbar - URL in Zwischenablage kopiert')),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      messenger.showSnackBar(
        const SnackBar(content: Text('URL in Zwischenablage kopiert')),
      );
    }
  }

  Future<void> _exportBlanko(BuildContext context, AmtlichesFormular f) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await rootBundle.load(f.assetPfad!);
      final bytes = data.buffer.asUint8List();
      final filename = f.assetPfad!.split('/').last.replaceAll('.pdf', '');
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: Uint8List.fromList(bytes),
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text('$filename.pdf gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Fehler: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
