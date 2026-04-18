import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/standort.dart';
import '../providers/app_provider.dart';
import '../services/distance_service.dart';

class StandorteScreen extends StatelessWidget {
  const StandorteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Standorte verwalten'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStandortDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final standorte = appProvider.standorte;

          if (standorte.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine Standorte angelegt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Tippen Sie auf + um einen Standort hinzuzufügen'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: standorte.length,
            itemBuilder: (context, index) {
              final standort = standorte[index];
              final isBuero = appProvider.settings.bueroStandortId == standort.id;

              return Card(
                child: ListTile(
                  leading: Icon(
                    _getIconForTyp(standort.typ),
                    color: isBuero ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(
                    standort.name,
                    style: isBuero
                        ? TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)
                        : null,
                  ),
                  subtitle: Text(
                    [
                      standort.typ.displayName,
                      if (isBuero) 'Standard-Büro',
                      if (standort.hasCoordinates) 'Koordinaten hinterlegt',
                      if (standort.clientId != null) 'Verknüpft mit Klient',
                    ].join(' · '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showStandortDialog(context, standort: standort);
                      } else if (value == 'delete') {
                        _confirmDelete(context, standort);
                      } else if (value == 'buero') {
                        final appProvider = Provider.of<AppProvider>(context, listen: false);
                        appProvider.updateSettings(
                          appProvider.settings.copyWith(bueroStandortId: standort.id),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                      if (standort.typ == StandortTyp.buero)
                        const PopupMenuItem(value: 'buero', child: Text('Als Standard-Büro setzen')),
                      const PopupMenuItem(value: 'delete', child: Text('Löschen')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForTyp(StandortTyp typ) {
    switch (typ) {
      case StandortTyp.buero:
        return Icons.business;
      case StandortTyp.klient:
        return Icons.person;
      case StandortTyp.amt:
        return Icons.account_balance;
      case StandortTyp.sonstige:
        return Icons.place;
    }
  }

  void _showStandortDialog(BuildContext context, {Standort? standort}) {
    showDialog(
      context: context,
      builder: (context) => _StandortEditDialog(standort: standort),
    );
  }

  void _confirmDelete(BuildContext context, Standort standort) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Standort löschen'),
        content: Text('Möchten Sie "${standort.name}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteStandort(standort.id);
              Navigator.pop(context);
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StandortEditDialog extends StatefulWidget {
  final Standort? standort;

  const _StandortEditDialog({this.standort});

  @override
  State<_StandortEditDialog> createState() => _StandortEditDialogState();
}

class _StandortEditDialogState extends State<_StandortEditDialog> {
  late final TextEditingController _nameController;
  final TextEditingController _searchController = TextEditingController();
  late StandortTyp _selectedTyp;
  String? _selectedClientId;
  double? _latitude;
  double? _longitude;

  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.standort?.name ?? '');
    _selectedTyp = widget.standort?.typ ?? StandortTyp.buero;
    _selectedClientId = widget.standort?.clientId;
    _latitude = widget.standort?.latitude;
    _longitude = widget.standort?.longitude;

    // Adress-Suche ist jetzt immer verfügbar (Nominatim, kein API-Key nötig)
    _hasApiKey = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);

    final service = DistanceService();
    final results = await service.searchAddresses(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(GeocodingResult result) {
    setState(() {
      _latitude = result.lat;
      _longitude = result.lng;
      _searchResults = [];
      _searchController.text = '${result.addressLine}, ${result.plzOrt}';
      // Name auto-befüllen falls noch leer
      if (_nameController.text.isEmpty) {
        _nameController.text = result.addressLine;
      }
    });
  }

  void _clearCoordinates() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final isEditing = widget.standort != null;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(isEditing ? 'Standort bearbeiten' : 'Neuer Standort'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Büro, Klient Müller, Amt Neukölln',
                  prefixIcon: Icon(Icons.label),
                ),
                autofocus: !_hasApiKey,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StandortTyp>(
                value: _selectedTyp,
                decoration: const InputDecoration(
                  labelText: 'Typ',
                  prefixIcon: Icon(Icons.category),
                ),
                items: StandortTyp.values.map((typ) => DropdownMenuItem(
                  value: typ,
                  child: Text(typ.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTyp = value;
                      if (value != StandortTyp.klient) {
                        _selectedClientId = null;
                      }
                    });
                  }
                },
              ),
              if (_selectedTyp == StandortTyp.klient) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedClientId,
                  decoration: const InputDecoration(
                    labelText: 'Klient (optional)',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Kein Klient')),
                    ...appProvider.clients.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedClientId = value),
                ),
              ],
              const SizedBox(height: 20),
              // Adress-Suche
              if (_hasApiKey) ...[
                Text(
                  'Adresse suchen (optional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adresse eingeben für automatische Distanzberechnung',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  autofocus: _hasApiKey && _nameController.text.isEmpty,
                  decoration: InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'z.B. Hauptstraße 1, 10827 Berlin',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearCoordinates,
                          )
                        : null,
                  ),
                  onChanged: _onSearchChanged,
                ),
                // Suchergebnisse
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            result.addressLine,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            result.plzOrt,
                            style: TextStyle(fontSize: 12, color: colorScheme.outline),
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
                // Koordinaten-Status
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Koordinaten hinterlegt',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: _clearCoordinates,
                          tooltip: 'Koordinaten entfernen',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            if (isEditing) {
              final updated = widget.standort!.copyWith(
                name: name,
                typ: _selectedTyp,
                clientId: _selectedClientId,
                latitude: _latitude,
                longitude: _longitude,
              );
              appProvider.updateStandort(updated);
            } else {
              final standort = Standort.create(
                name: name,
                typ: _selectedTyp,
                clientId: _selectedClientId,
                latitude: _latitude,
                longitude: _longitude,
              );
              appProvider.addStandort(standort);
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? 'Speichern' : 'Anlegen'),
        ),
      ],
    );
  }
}
