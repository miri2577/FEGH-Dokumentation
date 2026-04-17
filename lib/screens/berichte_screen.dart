import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bundesland.dart';
import '../models/informationsbericht.dart';
import '../providers/app_provider.dart';
import '../services/file_storage_service.dart';
import '../utils/responsive_utils.dart';
import 'informationsbericht_screen.dart';
import 'rechnungen/rechnungen_screen.dart';

class BerichteScreen extends StatefulWidget {
  const BerichteScreen({super.key});

  @override
  State<BerichteScreen> createState() => _BerichteScreenState();
}

class _BerichteScreenState extends State<BerichteScreen> {
  List<Informationsbericht> _entwuerfe = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntwuerfe();
  }

  Future<void> _loadEntwuerfe() async {
    final storage = FileStorageService();
    final berichte = await storage.loadBerichte();
    if (mounted) {
      setState(() {
        _entwuerfe = berichte..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berichte'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ResponsiveUtils.adaptiveScaffoldBody(
        context: context,
        body: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bericht erstellen',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInformationsberichtSektion(context),
              const SizedBox(height: 16),
              _buildRechnungenKarte(context),
              const SizedBox(height: 32),

              // Entwuerfe-Liste
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_entwuerfe.isNotEmpty) ...[
                Text(
                  'Gespeicherte Entwuerfe',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._entwuerfe.map((bericht) => _buildEntwurfKarte(context, bericht)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntwurfKarte(BuildContext context, Informationsbericht bericht) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final client = appProvider.clients.where((c) => c.id == bericht.clientId).firstOrNull;
    final clientName = client?.vollstaendigerName ?? 'Unbekannt';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.edit_note, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text('Informationsbericht: $clientName'),
        subtitle: Text(
          'Zuletzt bearbeitet: ${_formatDate(bericht.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Entwurf loeschen',
              onPressed: () => _deleteEntwurf(bericht),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          if (client != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => InformationsberichtScreen(
                  client: client,
                  existingBericht: bericht,
                ),
              ),
            ).then((_) => _loadEntwuerfe());
          }
        },
      ),
    );
  }

  Future<void> _deleteEntwurf(Informationsbericht bericht) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entwurf loeschen?'),
        content: const Text('Moechten Sie diesen Entwurf wirklich loeschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Loeschen')),
        ],
      ),
    );

    if (confirmed == true) {
      final storage = FileStorageService();
      final berichte = await storage.loadBerichte();
      berichte.removeWhere((b) => b.id == bericht.id);
      await storage.saveBerichte(berichte);
      _loadEntwuerfe();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRechnungenKarte(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RechnungenScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: Colors.teal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rechnungen (XRechnung)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Fachleistungsstunden als XRechnung-XML. Bundesweit standardisiert, '
                      'EN 16931 / UBL 2.1. Pflicht im B2G-Bereich.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationsberichtSektion(BuildContext context) {
    final settings = context.watch<AppProvider>().settings;
    final profil = BundeslandProfile.forLand(settings.bundesland);

    if (profil.informationsberichtBerlin101) {
      return _buildBerichtKarte(
        context,
        titel: 'Informationsbericht (Formular 101)',
        untertitel: 'Berliner Formular 101 fuer Leistungen der Eingliederungshilfe (v1.01)',
        icon: Icons.description,
        farbe: Theme.of(context).colorScheme.primary,
        onNeuErstellen: () => _neuerInformationsbericht(context),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informationsbericht nicht verfuegbar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Das Berliner Formular 101 ist nur bei Bundesland = Berlin verfuegbar. '
                    'Aktuell konfiguriert: ${profil.anzeigeName}. '
                    'Fuer "${profil.anzeigeName}" ist der Bericht noch nicht implementiert '
                    '(${profil.instrumentName}).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBerichtKarte(
    BuildContext context, {
    required String titel,
    required String untertitel,
    required IconData icon,
    required Color farbe,
    required VoidCallback onNeuErstellen,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: farbe.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: farbe, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        untertitel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNeuErstellen,
                icon: const Icon(Icons.add),
                label: const Text('Neu erstellen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _neuerInformationsbericht(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final clients = appProvider.clients;

    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte legen Sie zuerst einen Klienten an.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Klient auswaehlen'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              final idPrefix = client.klientenId != null ? '${client.klientenId} - ' : '';
              return ListTile(
                leading: CircleAvatar(
                  child: Text(client.vollstaendigerName.isNotEmpty
                      ? client.vollstaendigerName[0].toUpperCase()
                      : '?'),
                ),
                title: Text('$idPrefix${client.vollstaendigerName}'),
                subtitle: client.eingliederung != null ? Text(client.eingliederung!) : null,
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => InformationsberichtScreen(client: client),
                    ),
                  ).then((_) => _loadEntwuerfe());
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }
}
