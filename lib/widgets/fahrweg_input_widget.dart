import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/standort.dart';
import '../models/strecken_cache.dart';
import '../providers/app_provider.dart';
import '../services/distance_service.dart';

class FahrwegInputWidget extends StatefulWidget {
  final String? preSelectedClientId;
  final Function(FahrwegData hinfahrt, FahrwegData? rueckfahrt) onFahrwegChanged;

  const FahrwegInputWidget({
    super.key,
    this.preSelectedClientId,
    required this.onFahrwegChanged,
  });

  @override
  State<FahrwegInputWidget> createState() => _FahrwegInputWidgetState();
}

class FahrwegData {
  final String startStandortId;
  final String startStandortName;
  final String zielStandortId;
  final String zielStandortName;
  final double distanzKm;
  final String? clientId;

  const FahrwegData({
    required this.startStandortId,
    required this.startStandortName,
    required this.zielStandortId,
    required this.zielStandortName,
    required this.distanzKm,
    this.clientId,
  });
}

class _FahrwegInputWidgetState extends State<FahrwegInputWidget> {
  String? _startStandortId;
  String? _zielStandortId;
  final TextEditingController _distanzController = TextEditingController();
  bool _rueckfahrtGleich = false;
  bool _isCalculating = false;
  String? _berechnungsFehler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaults();
    });
  }

  void _initDefaults() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Standard-Büro als Start
    if (appProvider.settings.bueroStandortId != null) {
      setState(() {
        _startStandortId = appProvider.settings.bueroStandortId;
      });
    }

    // Klient-Standort als Ziel
    if (widget.preSelectedClientId != null) {
      final clientStandort = appProvider.getStandortForClient(widget.preSelectedClientId!);
      if (clientStandort != null) {
        setState(() {
          _zielStandortId = clientStandort.id;
        });
        _updateDistanzFromCache();
      }
    }
  }

  @override
  void dispose() {
    _distanzController.dispose();
    super.dispose();
  }

  void _updateDistanzFromCache() {
    if (_startStandortId == null || _zielStandortId == null) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final cached = appProvider.getCachedDistance(_startStandortId!, _zielStandortId!);
    if (cached != null) {
      _distanzController.text = cached.toStringAsFixed(1);
      _notifyParent();
    } else {
      // Automatisch per Koordinaten berechnen wenn beide Standorte Koordinaten haben
      _tryAutoCalculateFromCoords();
    }
  }

  Future<void> _tryAutoCalculateFromCoords() async {
    if (_startStandortId == null || _zielStandortId == null) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final start = appProvider.getStandortById(_startStandortId!);
    final ziel = appProvider.getStandortById(_zielStandortId!);
    if (start == null || ziel == null) return;
    if (!start.hasCoordinates || !ziel.hasCoordinates) return;

    setState(() => _isCalculating = true);

    final service = DistanceService();
    final distanz = await service.calculateDistanceFromCoords(
      start.latitude!, start.longitude!,
      ziel.latitude!, ziel.longitude!,
    );

    if (mounted && distanz != null) {
      _applyDistanz(distanz);
    }
    if (mounted) {
      setState(() => _isCalculating = false);
    }
  }

  void _notifyParent() {
    if (_startStandortId == null || _zielStandortId == null) return;
    final distanz = double.tryParse(_distanzController.text);
    if (distanz == null || distanz <= 0) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final start = appProvider.getStandortById(_startStandortId!);
    final ziel = appProvider.getStandortById(_zielStandortId!);
    if (start == null || ziel == null) return;

    final hinfahrt = FahrwegData(
      startStandortId: start.id,
      startStandortName: start.name,
      zielStandortId: ziel.id,
      zielStandortName: ziel.name,
      distanzKm: distanz,
      clientId: ziel.clientId ?? widget.preSelectedClientId,
    );

    FahrwegData? rueckfahrt;
    if (_rueckfahrtGleich) {
      rueckfahrt = FahrwegData(
        startStandortId: ziel.id,
        startStandortName: ziel.name,
        zielStandortId: start.id,
        zielStandortName: start.name,
        distanzKm: distanz,
        clientId: ziel.clientId ?? widget.preSelectedClientId,
      );
    }

    widget.onFahrwegChanged(hinfahrt, rueckfahrt);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final standorte = appProvider.standorte;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start-Standort
        DropdownButtonFormField<String>(
          value: _startStandortId,
          decoration: const InputDecoration(
            labelText: 'Start',
            prefixIcon: Icon(Icons.trip_origin),
          ),
          items: standorte.map((s) => DropdownMenuItem(
            value: s.id,
            child: Text(s.name),
          )).toList(),
          onChanged: (value) {
            setState(() => _startStandortId = value);
            _updateDistanzFromCache();
          },
        ),
        const SizedBox(height: 12),

        // Ziel-Standort
        DropdownButtonFormField<String>(
          value: _zielStandortId,
          decoration: InputDecoration(
            labelText: 'Ziel',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Neuen Standort anlegen',
              onPressed: () => _showNewStandortDialog(context),
            ),
          ),
          items: standorte
              .where((s) => s.id != _startStandortId)
              .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.name),
              ))
              .toList(),
          onChanged: (value) {
            setState(() => _zielStandortId = value);
            _updateDistanzFromCache();
          },
        ),
        const SizedBox(height: 12),

        // Distanz
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _distanzController,
                decoration: InputDecoration(
                  labelText: 'Distanz (km)',
                  prefixIcon: const Icon(Icons.straighten),
                  suffixText: 'km',
                  errorText: _berechnungsFehler,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _notifyParent(),
              ),
            ),
            const SizedBox(width: 8),
            _buildBerechnenButton(appProvider),
          ],
        ),
        const SizedBox(height: 12),

        // Rückfahrt
        CheckboxListTile(
          value: _rueckfahrtGleich,
          onChanged: (value) {
            setState(() => _rueckfahrtGleich = value ?? false);
            _notifyParent();
          },
          title: const Text('Rückfahrt gleich'),
          subtitle: const Text('Gleiche Strecke in Gegenrichtung'),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        // DSGVO-Hinweis wenn Berechnung aktiv
        if (_isCalculating)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
                const Text('Distanz wird berechnet...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBerechnenButton(AppProvider appProvider) {
    final hasCache = _startStandortId != null &&
        _zielStandortId != null &&
        appProvider.getCachedDistance(_startStandortId!, _zielStandortId!) != null;

    if (hasCache) {
      return const Tooltip(
        message: 'Distanz aus Cache geladen',
        child: Icon(Icons.check_circle, color: Colors.green),
      );
    }

    final canCalculate = _startStandortId != null && _zielStandortId != null && !_isCalculating;

    // Prüfen ob beide Standorte Koordinaten haben
    final start = _startStandortId != null ? appProvider.getStandortById(_startStandortId!) : null;
    final ziel = _zielStandortId != null ? appProvider.getStandortById(_zielStandortId!) : null;
    final bothHaveCoords = start?.hasCoordinates == true && ziel?.hasCoordinates == true;

    return FilledButton.tonalIcon(
      onPressed: canCalculate
          ? () {
              if (bothHaveCoords) {
                _tryAutoCalculateFromCoords();
              } else {
                _showDistanzBerechnungDialog();
              }
            }
          : null,
      icon: const Icon(Icons.calculate, size: 18),
      label: Text(bothHaveCoords ? 'Auto' : 'Berechnen'),
    );
  }

  void _showDistanzBerechnungDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _DistanzBerechnungDialog(
        onDistanzBerechnet: (distanz) {
          _applyDistanz(distanz);
        },
        onManuellEingeben: () {
          _showManuelleEingabe();
        },
      ),
    );
  }

  void _showManuelleEingabe() {
    // Fokus auf Distanz-Feld setzen
    _distanzController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _distanzController.text.length,
    );
  }

  void _applyDistanz(double distanz) {
    setState(() {
      _distanzController.text = distanz.toStringAsFixed(1);
      _berechnungsFehler = null;
    });

    // Im Cache speichern
    if (_startStandortId != null && _zielStandortId != null) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final existing = appProvider.getCachedDistance(_startStandortId!, _zielStandortId!);
      if (existing == null) {
        final cacheEntry = StreckenCache.create(
          startStandortId: _startStandortId!,
          zielStandortId: _zielStandortId!,
          distanzKm: distanz,
        );
        appProvider.addStreckenCacheEntry(cacheEntry);
      }
    }

    _notifyParent();
  }

  void _showNewStandortDialog(BuildContext context) {
    final nameController = TextEditingController();
    var selectedTyp = StandortTyp.klient;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Neuer Standort'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Klient Müller',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StandortTyp>(
                value: selectedTyp,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: StandortTyp.values.map((typ) => DropdownMenuItem(
                  value: typ,
                  child: Text(typ.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => selectedTyp = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final standort = Standort.create(
                  name: name,
                  typ: selectedTyp,
                  clientId: widget.preSelectedClientId,
                );
                Provider.of<AppProvider>(context, listen: false).addStandort(standort);
                Navigator.pop(context);

                // Neuen Standort als Ziel setzen
                setState(() => _zielStandortId = standort.id);
              },
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog mit Adress-Suche + PLZ-Vorschlägen für Start und Ziel
class _DistanzBerechnungDialog extends StatefulWidget {
  final Function(double distanz) onDistanzBerechnet;
  final VoidCallback onManuellEingeben;

  const _DistanzBerechnungDialog({
    required this.onDistanzBerechnet,
    required this.onManuellEingeben,
  });

  @override
  State<_DistanzBerechnungDialog> createState() => _DistanzBerechnungDialogState();
}

class _DistanzBerechnungDialogState extends State<_DistanzBerechnungDialog> {
  final _startController = TextEditingController();
  final _zielController = TextEditingController();

  List<GeocodingResult> _startResults = [];
  List<GeocodingResult> _zielResults = [];
  GeocodingResult? _selectedStart;
  GeocodingResult? _selectedZiel;

  bool _isSearchingStart = false;
  bool _isSearchingZiel = false;
  bool _isCalculating = false;
  double? _berechneteDistanz;

  Timer? _startDebounce;
  Timer? _zielDebounce;

  late final DistanceService _service;

  @override
  void initState() {
    super.initState();
    _service = DistanceService();
  }

  @override
  void dispose() {
    _startController.dispose();
    _zielController.dispose();
    _startDebounce?.cancel();
    _zielDebounce?.cancel();
    super.dispose();
  }

  void _onStartSearchChanged(String query) {
    _startDebounce?.cancel();
    setState(() => _selectedStart = null);
    if (query.trim().length < 3) {
      setState(() => _startResults = []);
      return;
    }
    _startDebounce = Timer(const Duration(milliseconds: 500), () => _searchStart(query));
  }

  void _onZielSearchChanged(String query) {
    _zielDebounce?.cancel();
    setState(() => _selectedZiel = null);
    if (query.trim().length < 3) {
      setState(() => _zielResults = []);
      return;
    }
    _zielDebounce = Timer(const Duration(milliseconds: 500), () => _searchZiel(query));
  }

  Future<void> _searchStart(String query) async {
    setState(() => _isSearchingStart = true);
    final results = await _service.searchAddresses(query);
    if (mounted) setState(() { _startResults = results; _isSearchingStart = false; });
  }

  Future<void> _searchZiel(String query) async {
    setState(() => _isSearchingZiel = true);
    final results = await _service.searchAddresses(query);
    if (mounted) setState(() { _zielResults = results; _isSearchingZiel = false; });
  }

  void _selectStart(GeocodingResult result) {
    setState(() {
      _selectedStart = result;
      _startController.text = '${result.addressLine}, ${result.plzOrt}';
      _startResults = [];
    });
  }

  void _selectZiel(GeocodingResult result) {
    setState(() {
      _selectedZiel = result;
      _zielController.text = '${result.addressLine}, ${result.plzOrt}';
      _zielResults = [];
    });
  }

  Future<void> _berechnen() async {
    if (_selectedStart == null || _selectedZiel == null) return;
    setState(() => _isCalculating = true);

    final distanz = await _service.getRouteDistance(_selectedStart!, _selectedZiel!);

    if (mounted) {
      setState(() {
        _isCalculating = false;
        if (distanz != null) {
          _berechneteDistanz = distanz;
        }
      });
      if (distanz == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berechnung fehlgeschlagen. Bitte prüfen Sie die Adressen.')),
        );
      }
    }
  }

  Widget _buildResultsList(List<GeocodingResult> results, Function(GeocodingResult) onSelect) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final result = results[index];
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.location_on, size: 18),
            title: Text(
              result.addressLine,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              result.plzOrt,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
            ),
            onTap: () => onSelect(result),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canCalculate = _selectedStart != null && _selectedZiel != null && !_isCalculating;

    return AlertDialog(
      title: const Text('Distanz berechnen'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Adresse eingeben und aus der Liste den korrekten Treffer mit PLZ auswählen.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Start-Adresse
              TextField(
                controller: _startController,
                decoration: InputDecoration(
                  labelText: 'Start-Adresse',
                  hintText: 'z.B. Hauptstraße 1, Berlin',
                  prefixIcon: const Icon(Icons.trip_origin),
                  suffixIcon: _selectedStart != null
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : _isSearchingStart
                          ? const SizedBox(width: 20, height: 20, child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                          : null,
                ),
                onChanged: _onStartSearchChanged,
              ),
              if (_startResults.isNotEmpty)
                _buildResultsList(_startResults, _selectStart),

              const SizedBox(height: 12),

              // Ziel-Adresse
              TextField(
                controller: _zielController,
                decoration: InputDecoration(
                  labelText: 'Ziel-Adresse',
                  hintText: 'z.B. Schönhauser Allee 5, Berlin',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: _selectedZiel != null
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                      : _isSearchingZiel
                          ? const SizedBox(width: 20, height: 20, child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                          : null,
                ),
                onChanged: _onZielSearchChanged,
              ),
              if (_zielResults.isNotEmpty)
                _buildResultsList(_zielResults, _selectZiel),

              // Ergebnis
              if (_berechneteDistanz != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '${_berechneteDistanz!.toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              if (_isCalculating)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onManuellEingeben();
          },
          child: const Text('Manuell eingeben'),
        ),
        if (_berechneteDistanz == null)
          FilledButton(
            onPressed: canCalculate ? _berechnen : null,
            child: const Text('Berechnen'),
          ),
        if (_berechneteDistanz != null)
          FilledButton(
            onPressed: () {
              widget.onDistanzBerechnet(_berechneteDistanz!);
              Navigator.pop(context);
            },
            child: const Text('Übernehmen'),
          ),
      ],
    );
  }
}
