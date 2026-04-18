import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import '../models/icf_bereiche.dart';
import '../models/familienhilfe_kategorien.dart';
import '../utils/responsive_utils.dart';
import '../utils/platform_utils.dart';
import '../models/fahrweg.dart';
import '../models/teilhabeziel.dart';
import '../services/wirkungsmessung_service.dart';
import '../widgets/fahrweg_input_widget.dart';
import 'create_client_screen.dart';
import 'wirkungsmessung/ziel_liste_screen.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final Client? preSelectedClient;
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  
  const CreateAppointmentScreen({
    super.key, 
    this.preSelectedClient,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  Client? _selectedClient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().addHour();
  String _recordedText = '';
  bool _isRecording = false;
  List<String> _selectedICFBereiche = [];
  List<String> _selectedFamilienhilfeKategorien = [];
  List<String> _selectedTIBBereiche = [];
  List<String> _selectedIndividuelleTIBZiele = [];
  Map<String, int> _tibZielMinuten = {};
  final WirkungsmessungService _wmService = WirkungsmessungService();
  List<Teilhabeziel> _teilhabeziele = [];
  FahrwegData? _fahrwegHin;
  FahrwegData? _fahrwegRueck;

  // Indirekte Termine
  TerminArt _selectedTerminArt = TerminArt.kliententermin;
  List<Client> _selectedAllocClients = [];
  Map<String, TextEditingController> _allocMinutenControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.preSelectedClient;
    
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    
    if (widget.initialStartTime != null) {
      _startTime = widget.initialStartTime!;
    }
    
    if (widget.initialEndTime != null) {
      _endTime = widget.initialEndTime!;
    }

    _loadTeilhabezieleFuerClient();
  }

  Future<void> _loadTeilhabezieleFuerClient() async {
    final c = _selectedClient;
    if (c == null) {
      if (mounted) setState(() => _teilhabeziele = []);
      return;
    }
    final alle = await _wmService.zieleFuerClient(c.id);
    // Nur aktive Ziele anzeigen - erreichte/abgebrochene sind nicht relevant fuer neue Termine
    final aktiv = alle.where((z) => z.status == TeilhabezielStatus.aktiv).toList();
    if (mounted) setState(() => _teilhabeziele = aktiv);
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _allocMinutenControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preSelectedClient != null 
            ? 'Dokumentation: ${widget.preSelectedClient!.name}'
            : 'Neuer Termin'),
        actions: [
          TextButton(
            onPressed: _saveAppointment,
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.clients.isEmpty) {
            return _buildNoClientsView(context);
          }

          return Form(
            key: _formKey,
            child: ResponsiveUtils.isDesktop(context) 
                ? _buildDesktopLayout(appProvider)
                : _buildMobileLayout(appProvider),
          );
        },
      ),
    );
  }

  Widget _buildNoClientsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Noch keine Klienten vorhanden',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie zuerst einen Klienten, um Termine zu dokumentieren.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateClientScreen(),
                ),
              );
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Klient erstellen'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AppProvider appProvider) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildAppointmentForm(appProvider),
          ),
        ),
        const VerticalDivider(),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: _buildSpeechSection(appProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AppProvider appProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAppointmentForm(appProvider),
          const SizedBox(height: 24),
          _buildSpeechSection(appProvider),
        ],
      ),
    );
  }

  Widget _buildAppointmentForm(AppProvider appProvider) {
    final bool isIndirect = _selectedTerminArt.isIndirect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TerminArt-Auswahl
        Text(
          'Art des Termins',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TerminArt.values.map((art) {
              final isSelected = _selectedTerminArt == art;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(art.displayName),
                  selected: isSelected,
                  avatar: Icon(
                    _getTerminArtIcon(art),
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTerminArt = art;
                        if (art.isIndirect) {
                          _selectedClient = null;
                        } else {
                          _selectedAllocClients = [];
                          for (final c in _allocMinutenControllers.values) {
                            c.dispose();
                          }
                          _allocMinutenControllers = {};
                        }
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Klientenauswahl: Dropdown für direkt, Multi-Select für indirekt
        if (!isIndirect && widget.preSelectedClient == null) ...[
          Text(
            'Klient auswählen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Client>(
            value: _selectedClient,
            decoration: const InputDecoration(
              labelText: 'Klient',
              hintText: 'Klient auswählen...',
              prefixIcon: Icon(Icons.person),
            ),
            items: appProvider.clients.map((client) {
              return DropdownMenuItem(
                value: client,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${client.berufsgruppe ?? 'Keine Angabe'} • ${client.eingliederung ?? 'Keine Angabe'}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (client) {
              setState(() {
                _selectedClient = client;
                _selectedIndividuelleTIBZiele = [];
                _tibZielMinuten = {};
              });
              _loadTeilhabezieleFuerClient();
            },
            validator: (value) {
              if (value == null && !isIndirect) {
                return 'Bitte wählen Sie einen Klienten aus';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
        ],

        // Multi-Klient-Verteilung für indirekte Termine
        if (isIndirect) ...[
          _buildClientAllocationSection(appProvider),
          const SizedBox(height: 24),
        ],

        Text(
          'Termin-Details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Datum
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Datum',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(_selectedDate)),
          ),
        ),
        const SizedBox(height: 16),
        
        // Zeit
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Von',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  child: Text(_startTime.format(context)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bis',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  child: Text(_endTime.format(context)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Notizen
        Text(
          'Dokumentation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notizen',
            hintText: 'Aktivitäten, Fortschritte, Besonderheiten...',
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          validator: (value) {
            if ((value == null || value.trim().isEmpty) && _recordedText.isEmpty) {
              return 'Bitte geben Sie Notizen ein oder nehmen Sie Text auf';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        
        // ICF/TIB/Familienhilfe nur bei direkten Kliententerminen
        if (!isIndirect) ...[
          // ICF-Bereiche
          _buildICFBereicheSection(),

          const SizedBox(height: 24),

          // TIB-Bereiche
          _buildTIBBereicheSection(),

          const SizedBox(height: 24),

          // Individuelle TIB-Ziele
          _buildIndividuelleTIBZieleSection(),

          const SizedBox(height: 24),

          // Familienhilfe-Kategorien (nur für Familienhilfe)
          _buildFamilienhilfeKategorienSection(),

          const SizedBox(height: 24),
        ],

        // Fahrweg dokumentieren
        _buildFahrwegSection(),
      ],
    );
  }

  Widget _buildFahrwegSection() {
    return ExpansionTile(
      leading: const Icon(Icons.directions_car),
      title: Text(
        'Fahrweg dokumentieren',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: _fahrwegHin != null
          ? Text('${_fahrwegHin!.startStandortName} → ${_fahrwegHin!.zielStandortName} (${_fahrwegHin!.distanzKm.toStringAsFixed(1)} km)')
          : const Text('Optional'),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FahrwegInputWidget(
            preSelectedClientId: _selectedClient?.id,
            onFahrwegChanged: (hinfahrt, rueckfahrt) {
              setState(() {
                _fahrwegHin = hinfahrt;
                _fahrwegRueck = rueckfahrt;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechSection(AppProvider appProvider) {
    if (!PlatformUtils.supportsSpeechToText) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.mic_off,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'Spracherkennung nicht verfügbar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                PlatformUtils.speechNotSupportedMessage,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording 
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sprachaufzeichnung',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (appProvider.isListening)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Aufnahme läuft...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (appProvider.speechEnabled) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: appProvider.isListening 
                          ? _stopRecording 
                          : _startRecording,
                      icon: Icon(appProvider.isListening ? Icons.stop : Icons.mic),
                      label: Text(appProvider.isListening ? 'Stop' : 'Aufnahme starten'),
                      style: FilledButton.styleFrom(
                        backgroundColor: appProvider.isListening 
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _recordedText.isNotEmpty ? _clearRecording : null,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Aufnahme löschen',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              FilledButton.icon(
                onPressed: _initializeSpeech,
                icon: const Icon(Icons.mic),
                label: const Text('Spracherkennung aktivieren'),
              ),
              const SizedBox(height: 16),
            ],
            
            // Erkannter Text
            if (_recordedText.isNotEmpty || appProvider.recognizedText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Erkannter Text:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recordedText.isNotEmpty 
                          ? _recordedText 
                          : appProvider.recognizedText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (appProvider.confidenceLevel > 0)
                LinearProgressIndicator(
                  value: appProvider.confidenceLevel,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
            ],
            
            if (appProvider.speechError.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fehler: ${appProvider.speechError}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (time != null) {
      setState(() {
        _startTime = time;
        // Automatisch Endzeit setzen (1 Stunde später)
        _endTime = time.addHour();
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (time != null && time.isAfter(_startTime)) {
      setState(() {
        _endTime = time;
      });
    } else if (time != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endzeit muss nach der Startzeit liegen')),
      );
    }
  }

  Future<void> _initializeSpeech() async {
    // TODO: Initialize speech recognition
  }

  Future<void> _startRecording() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _isRecording = true;
    });
    
    await appProvider.startSpeechRecognition(
      onResult: (text) {
        setState(() {
          _recordedText = appProvider.appendSpeechText(_recordedText, text);
          _isRecording = false;
        });
      },
      onPartialResult: (text) {
        // Live-Update der Erkennung
      },
    );
  }

  Future<void> _stopRecording() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.stopSpeechRecognition();
    setState(() {
      _isRecording = false;
    });
  }

  void _clearRecording() {
    setState(() {
      _recordedText = '';
    });
  }

  /// Prueft pro betroffenem Klienten, ob das FLS-Budget im aktuellen
  /// Abrechnungszeitraum ueberschritten wuerde.
  /// Gibt false zurueck wenn Nutzer abbricht.
  Future<bool> _pruefeBudget(AppProvider app, bool isIndirect) async {
    final betroffene = <(Client, double)>[]; // (Klient, geplante FLS aus diesem Termin)
    if (isIndirect) {
      for (final c in _selectedAllocClients) {
        final min = int.tryParse(_allocMinutenControllers[c.id]?.text ?? '') ?? 0;
        if (min > 0) betroffene.add((c, min / 60.0));
      }
    } else if (_selectedClient != null) {
      final dauer = _calculateAppointmentDurationInMinutes();
      betroffene.add((_selectedClient!, dauer / 60.0));
    }

    final warnungen = <String>[];
    final blocker = <String>[];
    for (final (client, geplantFls) in betroffene) {
      if (client.fachleistungsstunden == null) continue;
      final verbraucht = app.getFlsVerbrauchImAktuellenZeitraum(client, bezugsDatum: _selectedDate);
      final budget = client.fachleistungsstunden!.toDouble();
      final neuGesamt = verbraucht + geplantFls;
      final prozent = (neuGesamt / budget * 100);
      final intervallText = client.fachleistungsIntervall?.displayName ?? 'gesamt';

      if (prozent >= 100) {
        blocker.add('${client.vollstaendigerName}: ${neuGesamt.toStringAsFixed(1)} / '
            '$budget h $intervallText (${prozent.toStringAsFixed(0)} %)');
      } else if (prozent >= 90) {
        warnungen.add('${client.vollstaendigerName}: ${neuGesamt.toStringAsFixed(1)} / '
            '$budget h $intervallText (${prozent.toStringAsFixed(0)} %)');
      }
    }

    if (blocker.isEmpty && warnungen.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(blocker.isNotEmpty ? Icons.error : Icons.warning_amber,
            color: blocker.isNotEmpty ? Colors.red : Colors.orange, size: 40),
        title: Text(blocker.isNotEmpty
            ? 'Budget-Ueberschreitung'
            : 'Budget-Warnung (>= 90 %)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blocker.isNotEmpty) ...[
                const Text(
                  'Bewilligtes FLS-Kontingent wird ueberschritten:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const SizedBox(height: 4),
                ...blocker.map((t) => Text('• $t', style: const TextStyle(fontSize: 13))),
                const SizedBox(height: 12),
                const Text(
                  'Ohne Fortschreibung des Bewilligungsbescheids trägt das Risiko '
                  'der Leistungserbringer. Der Kostenträger kürzt auf das '
                  'bewilligte Maß.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (warnungen.isNotEmpty) ...[
                if (blocker.isNotEmpty) const SizedBox(height: 16),
                const Text(
                  'Nahe am Budget-Limit:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 4),
                ...warnungen.map((t) => Text('• $t', style: const TextStyle(fontSize: 13))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: blocker.isNotEmpty ? Colors.red.shade700 : null,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(blocker.isNotEmpty ? 'Trotzdem speichern' : 'Speichern'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool isIndirect = _selectedTerminArt.isIndirect;

    // Validierung je nach TerminArt
    if (!isIndirect && _selectedClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wählen Sie einen Klienten aus')),
      );
      return;
    }

    if (isIndirect && _selectedAllocClients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wählen Sie mindestens einen Klienten aus')),
      );
      return;
    }

    // Validierung: Minuten-Verteilung bei indirekten Terminen
    if (isIndirect) {
      final totalAllocMinuten = _selectedAllocClients.fold<int>(0, (sum, client) {
        final controller = _allocMinutenControllers[client.id];
        return sum + (int.tryParse(controller?.text ?? '') ?? 0);
      });
      final terminDauer = _calculateAppointmentDurationInMinutes();
      if (totalAllocMinuten > terminDauer) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'Verteilte Minuten ($totalAllocMinuten) ueberschreiten die Termindauer '
            '($terminDauer Min) - Doppelabrechnungs-Risiko',
          )),
        );
        return;
      }
      if (totalAllocMinuten != terminDauer) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verteilte Minuten ($totalAllocMinuten) stimmen nicht mit der Termindauer ($terminDauer Min) überein')),
        );
        return;
      }
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Budget-Check: bei Ueberschreitung des FLS-Kontingents warnen
    if (!await _pruefeBudget(appProvider, isIndirect)) return;

    final startDateTime = _combineDateAndTime(_selectedDate, _startTime);
    final endDateTime = _combineDateAndTime(_selectedDate, _endTime);

    // Fahrwege speichern (falls vorhanden)
    String? fahrwegHinId;
    String? fahrwegRueckId;

    if (_fahrwegHin != null) {
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
      fahrwegHinId = hinFahrweg.id;
    }

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
      fahrwegRueckId = rueckFahrweg.id;
    }

    // ClientAllocations für indirekte Termine
    List<ClientAllocation>? allocations;
    if (isIndirect) {
      allocations = _selectedAllocClients.map((client) {
        final controller = _allocMinutenControllers[client.id];
        final minuten = int.tryParse(controller?.text ?? '') ?? 0;
        return ClientAllocation(
          clientId: client.id,
          clientName: client.name,
          minuten: minuten,
        );
      }).toList();
    }

    final appointment = Appointment.create(
      clientId: isIndirect ? '_indirect_' : _selectedClient!.id,
      clientName: isIndirect ? _selectedTerminArt.displayName : _selectedClient!.name,
      date: _selectedDate,
      startTime: startDateTime,
      endTime: endDateTime,
      notes: _notesController.text.trim(),
      recordedText: _recordedText,
      berufsgruppe: isIndirect ? '' : (_selectedClient!.berufsgruppe ?? 'Nicht angegeben'),
      eingliederung: isIndirect ? '' : (_selectedClient!.eingliederung ?? 'Nicht angegeben'),
      icfBereiche: isIndirect ? const [] : _selectedICFBereiche,
      fachleistungsstunden: _calculateFachleistungsstunden(startDateTime, endDateTime),
      familienhilfeKategorien: isIndirect ? const [] : _selectedFamilienhilfeKategorien,
      tibBereiche: isIndirect ? const [] : _selectedTIBBereiche,
      selectedTibZiele: isIndirect ? null : (_selectedIndividuelleTIBZiele.isNotEmpty ? _selectedIndividuelleTIBZiele : null),
      tibZielMinuten: isIndirect ? null : (_tibZielMinuten.isNotEmpty ? _tibZielMinuten : null),
      fahrwegHinId: fahrwegHinId,
      fahrwegRueckId: fahrwegRueckId,
      terminArt: _selectedTerminArt,
      clientAllocations: allocations,
    );

    final success = await appProvider.addAppointment(appointment);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Termin erfolgreich gespeichert')),
      );
      Navigator.pop(context);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  double _calculateFachleistungsstunden(DateTime startDateTime, DateTime endDateTime) {
    final duration = endDateTime.difference(startDateTime);
    return duration.inMinutes / 60.0;
  }

  // ICF-Bereiche Sektion
  Widget _buildICFBereicheSection() {
    if (_selectedClient == null) {
      return const SizedBox.shrink();
    }

    // Bestimme verfügbare ICF-Bereiche basierend auf dem Hilfe-Typ des Klienten
    List<ICFBereich> verfuegbareBereiche;
    String sectionTitle;
    
    if (_selectedClient!.hilfeTyp == HilfeTyp.familienhilfe) {
      verfuegbareBereiche = ICFBereiche.familienhilfe;
      sectionTitle = 'ICF-Bereiche (Familienhilfe)';
    } else {
      verfuegbareBereiche = ICFBereiche.eingliederungshilfe;
      sectionTitle = 'ICF-Bereiche (Eingliederungshilfe)';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Wählen Sie die relevanten ICF-Bereiche für diese Dokumentation aus:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: verfuegbareBereiche.map((bereich) {
              final isSelected = _selectedICFBereiche.contains(bereich.id);
              return CheckboxListTile(
                title: Text(
                  bereich.titel,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(bereich.beschreibung),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedICFBereiche.add(bereich.id);
                    } else {
                      _selectedICFBereiche.remove(bereich.id);
                    }
                  });
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            }).toList(),
          ),
        ),
        if (_selectedICFBereiche.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedICFBereiche.map((bereichId) {
              final bereich = ICFBereiche.getById(bereichId);
              if (bereich == null) return const SizedBox.shrink();
              return Chip(
                label: Text(bereich.titel),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedICFBereiche.remove(bereichId);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // TIB-Bereiche Sektion
  Widget _buildTIBBereicheSection() {
    if (_selectedClient == null || _selectedClient!.tibZiele == null || _selectedClient!.tibZiele!.isEmpty) {
      return const SizedBox.shrink();
    }

    final tibBereiche = [
      'Lernen und Wissensanwendung',
      'Allgemeine Aufgaben und Anforderungen',
      'Kommunikation',
      'Mobilität',
      'Selbstversorgung',
      'Häusliches Leben',
      'Interpersonelle Interaktionen und Beziehungen',
      'Bedeutende Lebensbereiche',
      'Gemeinschafts-, soziales und staatsbürgerliches Leben',
    ];

    // Nur TIB-Bereiche anzeigen, die für diesen Klienten definiert sind
    final verfuegbareBereiche = tibBereiche
        .where((bereich) => _selectedClient!.tibZiele!.contains(bereich))
        .toList();

    if (verfuegbareBereiche.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIB-Bereiche (Teilhabeinstrument Berlin)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Dokumentieren Sie den Fortschritt in den definierten TIB-Zielbereichen:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: verfuegbareBereiche.map((bereich) {
              final isSelected = _selectedTIBBereiche.contains(bereich);
              return CheckboxListTile(
                title: Text(
                  bereich,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(_getTIBBeschreibung(bereich)),
                secondary: const Icon(Icons.psychology, color: Colors.blue),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedTIBBereiche.add(bereich);
                    } else {
                      _selectedTIBBereiche.remove(bereich);
                    }
                  });
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            }).toList(),
          ),
        ),
        if (_selectedTIBBereiche.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTIBBereiche.map((bereich) {
              return Chip(
                label: Text(bereich),
                backgroundColor: Colors.blue.shade50,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedTIBBereiche.remove(bereich);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _getTIBBeschreibung(String bereich) {
    switch (bereich) {
      case 'Lernen und Wissensanwendung':
        return 'Aufmerksamkeit, Gedächtnis, Problemlösung';
      case 'Allgemeine Aufgaben und Anforderungen':
        return 'Tagesroutine, Umgang mit Stress und Anforderungen';
      case 'Kommunikation':
        return 'Verstehen und Produzieren von Sprache';
      case 'Mobilität':
        return 'Fortbewegung und Körperhaltung';
      case 'Selbstversorgung':
        return 'Körperpflege, An- und Ausziehen, Essen';
      case 'Häusliches Leben':
        return 'Haushaltsführung, Wohnen, Alltag';
      case 'Interpersonelle Interaktionen und Beziehungen':
        return 'Soziale Kontakte und Beziehungen';
      case 'Bedeutende Lebensbereiche':
        return 'Bildung, Arbeit, Wirtschaftsleben';
      case 'Gemeinschafts-, soziales und staatsbürgerliches Leben':
        return 'Gemeinschaftsleben, Erholung, Religion, Politik';
      default:
        return 'TIB-Zielbereich';
    }
  }

  // Teilhabeziele-Sektion (aus Wirkungsmessung)
  Widget _buildIndividuelleTIBZieleSection() {
    if (_selectedClient == null) return const SizedBox.shrink();

    // Nachtrag: Falls altes Klient-Profil noch individuelleTibZiele hat,
    // Banner zur Migration zeigen
    final legacyVorhanden = (_selectedClient!.individuelleTibZiele ?? []).isNotEmpty;

    if (_teilhabeziele.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teilhabeziele', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    legacyVorhanden
                        ? 'Klient hat alte TIB-Ziele im Profil. Bitte zuerst als Teilhabeziele uebernehmen.'
                        : 'Noch keine aktiven Teilhabeziele fuer diesen Klienten angelegt.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final appProvider = context.read<AppProvider>();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ZielListeScreen(
                          client: _selectedClient!,
                          bewertetVon: appProvider.settings.userName,
                        ),
                      ),
                    );
                    await _loadTeilhabezieleFuerClient();
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Anlegen'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Teilhabeziele', style: Theme.of(context).textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: () async {
                final appProvider = context.read<AppProvider>();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ZielListeScreen(
                      client: _selectedClient!,
                      bewertetVon: appProvider.settings.userName,
                    ),
                  ),
                );
                await _loadTeilhabezieleFuerClient();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Verwalten'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'An welchen Teilhabezielen wurde in diesem Termin gearbeitet, und wie lange?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: _teilhabeziele.map((tz) {
              // Als Storage-Schluessel wird weiterhin der Titel genutzt
              // (backward-compatible zu bestehenden Appointment-Datensaetzen).
              final key = tz.titel;
              final isSelected = _selectedIndividuelleTIBZiele.contains(key);
              final minuten = _tibZielMinuten[key] ?? 0;

              return ExpansionTile(
                key: ValueKey(tz.id),
                leading: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIndividuelleTIBZiele.add(key);
                        _tibZielMinuten[key] ??= 30;
                      } else {
                        _selectedIndividuelleTIBZiele.remove(key);
                        _tibZielMinuten.remove(key);
                      }
                    });
                  },
                ),
                title: Text(
                  tz.titel,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                ),
                subtitle: Text(
                  isSelected
                      ? 'Arbeitszeit: $minuten Minuten${tz.icfBereich != null ? " • ICF: ${tz.icfBereich}" : ""}'
                      : '${tz.kategorieDisplayName} • Prio ${tz.prioritaet}/5${tz.icfBereich != null ? " • ${tz.icfBereich}" : ""}',
                  style: TextStyle(color: isSelected ? Theme.of(context).primaryColor : null),
                ),
                initiallyExpanded: isSelected,
                children: [
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Slider(
                              value: minuten.toDouble(),
                              min: 5,
                              max: 180,
                              divisions: 35,
                              label: '$minuten Min',
                              onChanged: (double value) {
                                setState(() {
                                  _tibZielMinuten[key] = value.round();
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: minuten.toString(),
                              decoration: const InputDecoration(
                                suffixText: 'Min',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final parsedValue = int.tryParse(value);
                                if (parsedValue != null && parsedValue > 0 && parsedValue <= 480) {
                                  setState(() {
                                    _tibZielMinuten[key] = parsedValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),

        if (_selectedIndividuelleTIBZiele.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTibZielZeitUebersicht(),
        ],
      ],
    );
  }

  Widget _buildTibZielZeitUebersicht() {
    final gesamtMinuten = _tibZielMinuten.values.fold(0, (sum, minuten) => sum + minuten);
    final terminDauer = _calculateAppointmentDurationInMinutes();
    final restzeit = terminDauer - gesamtMinuten;
    final isUeberschritten = gesamtMinuten > terminDauer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUeberschritten
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Zeitübersicht',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isUeberschritten)
                Icon(
                  Icons.warning,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Termine-Gesamtdauer:'),
              Text('${terminDauer} Min', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TIB-Ziele gesamt:'),
              Text(
                '${gesamtMinuten} Min',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isUeberschritten ? Theme.of(context).colorScheme.error : null,
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isUeberschritten ? 'Überschreitung:' : 'Restzeit:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUeberschritten
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '${restzeit.abs()} Min',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isUeberschritten
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          if (isUeberschritten) ...[
            const SizedBox(height: 8),
            Text(
              'Achtung: Die eingetragenen TIB-Zeiten überschreiten die Termindauer!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _calculateAppointmentDurationInMinutes() {
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
    return endDateTime.difference(startDateTime).inMinutes;
  }

  // Familienhilfe-Kategorien Sektion
  Widget _buildFamilienhilfeKategorienSection() {
    if (_selectedClient == null || _selectedClient!.hilfeTyp != HilfeTyp.familienhilfe) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dokumentationskategorien (Familienhilfe)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Wählen Sie die Art der Dokumentation für diesen Termin:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: FamilienhilfeKategorien.alle.map((kategorie) {
              final isSelected = _selectedFamilienhilfeKategorien.contains(kategorie.id);
              return CheckboxListTile(
                title: Text(
                  kategorie.titel,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(kategorie.beschreibung),
                secondary: _getFamilienhilfeIcon(kategorie.icon),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedFamilienhilfeKategorien.add(kategorie.id);
                    } else {
                      _selectedFamilienhilfeKategorien.remove(kategorie.id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        if (_selectedFamilienhilfeKategorien.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Ausgewählte Kategorien:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedFamilienhilfeKategorien.map((kategorieId) {
              final kategorie = FamilienhilfeKategorien.getById(kategorieId);
              if (kategorie == null) return const SizedBox.shrink();
              return Chip(
                avatar: _getFamilienhilfeIcon(kategorie.icon),
                label: Text(kategorie.titel),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedFamilienhilfeKategorien.remove(kategorieId);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _getFamilienhilfeIcon(String iconName) {
    switch (iconName) {
      case 'person':
        return const Icon(Icons.person, size: 20);
      case 'people':
        return const Icon(Icons.people, size: 20);
      case 'family_restroom':
        return const Icon(Icons.family_restroom, size: 20);
      case 'school':
        return const Icon(Icons.school, size: 20);
      case 'emergency':
        return const Icon(Icons.emergency, size: 20);
      case 'trending_up':
        return const Icon(Icons.trending_up, size: 20);
      default:
        return const Icon(Icons.category, size: 20);
    }
  }

  // TerminArt Icon Helper
  IconData _getTerminArtIcon(TerminArt art) {
    switch (art) {
      case TerminArt.kliententermin:
        return Icons.person;
      case TerminArt.buero:
        return Icons.business;
      case TerminArt.dokumentation:
        return Icons.description;
      case TerminArt.supervision:
        return Icons.psychology;
      case TerminArt.teamsitzung:
        return Icons.groups;
      case TerminArt.fortbildung:
        return Icons.school;
      case TerminArt.fahrtzeit:
        return Icons.directions_car;
      case TerminArt.sonstige:
        return Icons.more_horiz;
    }
  }

  // Multi-Klient-Verteilungs-Widget
  Widget _buildClientAllocationSection(AppProvider appProvider) {
    final terminDauer = _calculateAppointmentDurationInMinutes();
    final totalAllocMinuten = _selectedAllocClients.fold<int>(0, (sum, client) {
      final controller = _allocMinutenControllers[client.id];
      return sum + (int.tryParse(controller?.text ?? '') ?? 0);
    });
    final restMinuten = terminDauer - totalAllocMinuten;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Klienten auswählen & Stunden verteilen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Wählen Sie die Klienten aus, auf die dieser ${_selectedTerminArt.displayName}-Termin verteilt werden soll:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 12),

        // Klienten-Checkboxen
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appProvider.clients.length,
            itemBuilder: (context, index) {
              final client = appProvider.clients[index];
              final isSelected = _selectedAllocClients.any((c) => c.id == client.id);
              return CheckboxListTile(
                title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(client.berufsgruppe ?? ''),
                value: isSelected,
                dense: true,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedAllocClients.add(client);
                      _allocMinutenControllers[client.id] = TextEditingController(text: '0');
                    } else {
                      _selectedAllocClients.removeWhere((c) => c.id == client.id);
                      _allocMinutenControllers[client.id]?.dispose();
                      _allocMinutenControllers.remove(client.id);
                    }
                  });
                },
              );
            },
          ),
        ),

        if (_selectedAllocClients.isNotEmpty) ...[
          const SizedBox(height: 16),

          // Gleichmäßig-verteilen-Button
          OutlinedButton.icon(
            onPressed: () {
              final perClient = terminDauer ~/ _selectedAllocClients.length;
              final rest = terminDauer % _selectedAllocClients.length;
              setState(() {
                for (int i = 0; i < _selectedAllocClients.length; i++) {
                  final client = _selectedAllocClients[i];
                  final minuten = perClient + (i < rest ? 1 : 0);
                  _allocMinutenControllers[client.id]?.text = minuten.toString();
                }
              });
            },
            icon: const Icon(Icons.balance, size: 18),
            label: const Text('Gleichmäßig verteilen'),
          ),
          const SizedBox(height: 12),

          // Minuten pro Klient
          ...List.generate(_selectedAllocClients.length, (index) {
            final client = _selectedAllocClients[index];
            final controller = _allocMinutenControllers[client.id]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      client.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        suffixText: 'Min',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Zusammenfassungsleiste
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: restMinuten == 0
                  ? Theme.of(context).colorScheme.primaryContainer
                  : restMinuten < 0
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Termindauer:'),
                    Text('$terminDauer Min', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Verteilt:'),
                    Text('$totalAllocMinuten Min', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      restMinuten < 0 ? 'Überschritten:' : 'Rest:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: restMinuten == 0
                            ? Theme.of(context).colorScheme.primary
                            : restMinuten < 0
                                ? Theme.of(context).colorScheme.error
                                : null,
                      ),
                    ),
                    Text(
                      '${restMinuten.abs()} Min',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: restMinuten == 0
                            ? Theme.of(context).colorScheme.primary
                            : restMinuten < 0
                                ? Theme.of(context).colorScheme.error
                                : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

extension TimeOfDayExtension on TimeOfDay {
  TimeOfDay addHour() {
    return TimeOfDay(
      hour: (hour + 1) % 24,
      minute: minute,
    );
  }

  bool isAfter(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }
}