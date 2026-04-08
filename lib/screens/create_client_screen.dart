import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/client.dart';
import '../models/mitarbeiter.dart';
import '../models/tib_ziel.dart';
import '../models/kostentraeger.dart';
import '../models/icf_bereiche.dart';
import '../utils/responsive_utils.dart';

class CreateClientScreen extends StatefulWidget {
  final Client? client;

  const CreateClientScreen({super.key, this.client});

  @override
  State<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends State<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _klientenIdController;
  late TextEditingController _vornameController;
  late TextEditingController _nachnameController;
  late TextEditingController _fachleistungsstundenController;
  late TextEditingController _kalkulationsfaktorOverrideController;
  late TextEditingController _stundensatzOverrideController;

  String _selectedEingliederung = '';
  String _selectedKostentraeger = '';
  String? _selectedRechtsgrundlage;
  HilfeTyp _selectedHilfeTyp = HilfeTyp.eingliederungshilfe;
  FachleistungsIntervall _selectedIntervall = FachleistungsIntervall.monatlich;

  DateTime? _selectedGeburtsdatum;
  DateTime? _selectedBetreuungSeit;
  DateTime? _selectedKostenuebernahmeVon;
  DateTime? _selectedKostenuebernahmeBis;

  String? _selectedVertreter1Id;
  String? _selectedVertreter2Id;
  List<String> _selectedTibZiele = [];
  List<TextEditingController> _individuelleTibZieleControllers = [];

  static const List<String> eingliederungsarten = [
    '', // Leere Option als erste Option
    'Berufliche Reha',
    'Soziale Teilhabe',
    'Medizinische Reha',
    'Teilhabe Arbeit',
    'Teilhabe Bildung',
    'Sonstige'
  ];

  static const List<Map<String, String>> rechtsgrundlagen = [
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 99 SGB IX – Leistungsberechtigter Personenkreis'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 102 SGB IX – Aufgabe der Eingliederungshilfe'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 111 SGB IX – Leistungen zur Sozialen Teilhabe'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 112 SGB IX – Leistungen zur Teilhabe an Bildung'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 113 SGB IX – Heilpädagogische Leistungen'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 116 SGB IX – Assistenzleistungen'},
    {'gruppe': 'SGB IX (Eingliederungshilfe)', 'wert': '§ 78 SGB IX – Teilhabe am Arbeitsleben'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 35a SGB VIII – Eingliederungshilfe (seelische Behinderung)'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 27 SGB VIII – Hilfe zur Erziehung'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 30 SGB VIII – Erziehungsbeistand'},
    {'gruppe': 'SGB VIII (Jugendhilfe)', 'wert': '§ 31 SGB VIII – SPFH'},
    {'gruppe': 'SGB XII (Sozialhilfe)', 'wert': '§ 67 SGB XII – Personen in besonderen Lebenslagen'},
  ];

  @override
  void initState() {
    super.initState();

    // Controller initialisieren
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _klientenIdController = TextEditingController(text: widget.client?.klientenId ?? '');
    _vornameController = TextEditingController(text: widget.client?.vorname ?? '');
    _nachnameController = TextEditingController(text: widget.client?.nachname ?? '');
    _fachleistungsstundenController = TextEditingController(
      text: widget.client?.fachleistungsstunden?.toString() ?? '120'
    );
    _kalkulationsfaktorOverrideController = TextEditingController(
      text: widget.client?.kalkulationsfaktorOverride?.toStringAsFixed(2) ?? '',
    );
    _stundensatzOverrideController = TextEditingController(
      text: widget.client?.stundensatzOverride?.toStringAsFixed(2) ?? '',
    );

    // Listener für automatische Name-Aktualisierung
    _vornameController.addListener(_updateFullName);
    _nachnameController.addListener(_updateFullName);

    // Dropdowns initialisieren - KEINE automatischen Standardwerte setzen
    final clientEingliederung = widget.client?.eingliederung ?? '';
    _selectedEingliederung = eingliederungsarten.contains(clientEingliederung)
        ? clientEingliederung
        : ''; // Leer lassen statt automatischen Standardwert

    // Neue Felder initialisieren
    _selectedHilfeTyp = widget.client?.hilfeTyp ?? HilfeTyp.eingliederungshilfe;
    _selectedIntervall = widget.client?.fachleistungsIntervall ?? FachleistungsIntervall.monatlich;
    _selectedKostentraeger = widget.client?.kostenuebernahme ?? '';
    _selectedGeburtsdatum = widget.client?.geburtsdatum;
    _selectedBetreuungSeit = widget.client?.betreuungSeit;
    _selectedKostenuebernahmeVon = widget.client?.kostenuebernahmeVon;
    _selectedKostenuebernahmeBis = widget.client?.kostenuebernahmeBis;
    _selectedVertreter1Id = widget.client?.vertreter1Id;
    _selectedVertreter2Id = widget.client?.vertreter2Id;
    _selectedTibZiele = widget.client?.tibZiele ?? [];
    _selectedRechtsgrundlage = widget.client?.rechtsgrundlage;

    // Individuelle TIB-Ziele Controller initialisieren
    final individuelleTibZiele = widget.client?.individuelleTibZiele ?? [];
    _individuelleTibZieleControllers = individuelleTibZiele.map((ziel) => TextEditingController(text: ziel)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _klientenIdController.dispose();
    _vornameController.dispose();
    _nachnameController.dispose();
    _fachleistungsstundenController.dispose();
    _kalkulationsfaktorOverrideController.dispose();
    _stundensatzOverrideController.dispose();
    for (var controller in _individuelleTibZieleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateFullName() {
    if (_vornameController.text.isNotEmpty && _nachnameController.text.isNotEmpty) {
      setState(() {
        _nameController.text = '${_vornameController.text} ${_nachnameController.text}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client == null ? 'Neuer Klient' : 'Klient bearbeiten'),
        actions: [
          TextButton(
            onPressed: () => _saveClient(context),
            child: const Text('Speichern'),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grunddaten Sektion
                  Text(
                    'Grunddaten',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildGrunddatenCard(),

                  const SizedBox(height: 24),

                  // Betreuung Sektion
                  Text(
                    'Betreuung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBetreuungCard(),

                  const SizedBox(height: 24),

                  // Fachleistungsstunden Sektion
                  Text(
                    'Fachleistungsstunden',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFachleistungCard(),

                  const SizedBox(height: 24),

                  // Vertreter Sektion
                  Text(
                    'Vertreter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildVertreterCard(appProvider),

                  const SizedBox(height: 24),

                  // TIB-Ziele Sektion
                  Text(
                    'TIB-Ziele (Teilhabeinstrument Berlin)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTibZieleCard(),

                  const SizedBox(height: 100), // Space for navigation
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrunddatenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Vollständiger Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                helperText: 'Wird automatisch aus Vor- und Nachnamen generiert',
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _klientenIdController,
              decoration: const InputDecoration(
                labelText: 'Klienten-ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: 'z.B. KL-001',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vornameController,
              decoration: const InputDecoration(
                labelText: 'Vorname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Vorname eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nachnameController,
              decoration: const InputDecoration(
                labelText: 'Nachname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte Nachname eingeben';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedEingliederung.isEmpty ? null : _selectedEingliederung,
              decoration: const InputDecoration(
                labelText: 'Eingliederungsart',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: eingliederungsarten.map((String value) {
                return DropdownMenuItem<String>(
                  value: value.isEmpty ? null : value,
                  child: Text(value.isEmpty ? 'Bitte auswählen' : value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEingliederung = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRechtsgrundlage,
              decoration: const InputDecoration(
                labelText: 'Rechtsgrundlage / Paragraph',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gavel),
                hintText: 'Bitte auswählen',
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Keine Angabe'),
                ),
                ...(() {
                  String? currentGruppe;
                  final items = <DropdownMenuItem<String>>[];
                  for (final entry in rechtsgrundlagen) {
                    if (entry['gruppe'] != currentGruppe) {
                      currentGruppe = entry['gruppe'];
                      items.add(DropdownMenuItem<String>(
                        enabled: false,
                        value: 'header_$currentGruppe',
                        child: Text(
                          currentGruppe!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ));
                    }
                    items.add(DropdownMenuItem<String>(
                      value: entry['wert'],
                      child: Text(
                        entry['wert']!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ));
                  }
                  return items;
                })(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRechtsgrundlage = value;
                });
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context, 'geburtsdatum'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Geburtsdatum',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                child: Text(
                  _selectedGeburtsdatum != null
                      ? '${_selectedGeburtsdatum!.day}.${_selectedGeburtsdatum!.month}.${_selectedGeburtsdatum!.year}'
                      : 'Datum auswählen',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetreuungCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: () => _selectDate(context, 'betreuung_seit'),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Betreuung seit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_available),
                ),
                child: Text(
                  _selectedBetreuungSeit != null
                      ? '${_selectedBetreuungSeit!.day}.${_selectedBetreuungSeit!.month}.${_selectedBetreuungSeit!.year}'
                      : 'Datum auswählen',
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedKostentraeger.isEmpty ? null : _selectedKostentraeger,
              decoration: const InputDecoration(
                labelText: 'Kostenträger',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                hintText: 'Bitte auswählen',
              ),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Keine Angabe'),
                ),
                ...(() {
                  String? currentGruppe;
                  final items = <DropdownMenuItem<String>>[];
                  for (final entry in Kostentraeger.alleGruppiert) {
                    if (entry['gruppe'] != currentGruppe) {
                      currentGruppe = entry['gruppe'];
                      items.add(DropdownMenuItem<String>(
                        enabled: false,
                        value: 'header_$currentGruppe',
                        child: Text(
                          currentGruppe!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ));
                    }
                    items.add(DropdownMenuItem<String>(
                      value: entry['wert'],
                      child: Text(
                        entry['wert']!,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ));
                  }
                  return items;
                })(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedKostentraeger = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'kostenuebernahme_von'),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Von',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _selectedKostenuebernahmeVon != null
                            ? '${_selectedKostenuebernahmeVon!.day}.${_selectedKostenuebernahmeVon!.month}.${_selectedKostenuebernahmeVon!.year}'
                            : 'Datum auswählen',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, 'kostenuebernahme_bis'),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Bis',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        _selectedKostenuebernahmeBis != null
                            ? '${_selectedKostenuebernahmeBis!.day}.${_selectedKostenuebernahmeBis!.month}.${_selectedKostenuebernahmeBis!.year}'
                            : 'Datum auswählen',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFachleistungCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_klientenIdController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Klienten-ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  child: Text(_klientenIdController.text),
                ),
              ),
            TextFormField(
              controller: _fachleistungsstundenController,
              decoration: const InputDecoration(
                labelText: 'Fachleistungsstunden',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'Stunden',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final stunden = int.tryParse(value);
                  if (stunden == null || stunden <= 0) {
                    return 'Bitte gültige Stundenzahl eingeben';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FachleistungsIntervall>(
              value: _selectedIntervall,
              decoration: const InputDecoration(
                labelText: 'Intervall',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: FachleistungsIntervall.values.map((intervall) {
                return DropdownMenuItem<FachleistungsIntervall>(
                  value: intervall,
                  child: Text(switch (intervall) {
                    FachleistungsIntervall.woechentlich => 'Wöchentlich',
                    FachleistungsIntervall.monatlich => 'Monatlich',
                    FachleistungsIntervall.jaehrlich => 'Jährlich',
                  }),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedIntervall = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<HilfeTyp>(
              value: _selectedHilfeTyp,
              decoration: const InputDecoration(
                labelText: 'Hilfe-Typ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
              items: HilfeTyp.values.map((typ) {
                return DropdownMenuItem<HilfeTyp>(
                  value: typ,
                  child: Text(typ == HilfeTyp.eingliederungshilfe ? 'Eingliederungshilfe' : 'Familienhilfe'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHilfeTyp = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Klient-spezifische Kalkulation (optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            ),
            TextFormField(
              controller: _kalkulationsfaktorOverrideController,
              decoration: const InputDecoration(
                labelText: 'Kalkulationsfaktor (leer = global)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
                hintText: 'z.B. 1.25',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final v = double.tryParse(value.trim().replaceAll(',', '.'));
                  if (v == null || v <= 0) {
                    return 'Bitte gültigen Faktor eingeben';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stundensatzOverrideController,
              decoration: const InputDecoration(
                labelText: 'Stundensatz EUR (leer = global)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
                hintText: 'z.B. 44.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final v = double.tryParse(value.trim().replaceAll(',', '.'));
                  if (v == null || v <= 0) {
                    return 'Bitte gültigen Stundensatz eingeben';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVertreterCard(AppProvider appProvider) {
    final mitarbeiter = appProvider.mitarbeiter;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String?>(
              value: _selectedVertreter1Id,
              decoration: const InputDecoration(
                labelText: 'Vertreter 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Keine Auswahl'),
                ),
                ...mitarbeiter.toSet().map((m) {
                  return DropdownMenuItem<String?>(
                    value: m.id,
                    child: Text('${m.vorname} ${m.name} (Team ${m.teamNummer})'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVertreter1Id = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _selectedVertreter2Id,
              decoration: const InputDecoration(
                labelText: 'Vertreter 2',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Keine Auswahl'),
                ),
                ...mitarbeiter.toSet().map((m) {
                  return DropdownMenuItem<String?>(
                    value: m.id,
                    child: Text('${m.vorname} ${m.name} (Team ${m.teamNummer})'),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVertreter2Id = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTibZieleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Individuelle TIB-Ziele der Teilhabeplanung',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addIndividuelleTibZiel,
                  icon: const Icon(Icons.add),
                  tooltip: 'Neues TIB-Ziel hinzufügen',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tragen Sie hier die individuellen TIB-Ziele für diesen Klienten ein. Diese können später in der Dokumentation ausgewählt und mit Betreuungszeiten versehen werden.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_individuelleTibZieleControllers.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Noch keine individuellen TIB-Ziele angelegt. Klicken Sie auf das Plus-Symbol, um ein Ziel hinzuzufügen.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._individuelleTibZieleControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'TIB-Ziel ${index + 1}',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.flag),
                            hintText: 'z.B. Verbesserung der Kommunikationsfähigkeiten',
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Bitte geben Sie ein TIB-Ziel ein';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeIndividuelleTibZiel(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'TIB-Ziel entfernen',
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _addIndividuelleTibZiel() {
    setState(() {
      _individuelleTibZieleControllers.add(TextEditingController());
    });
  }

  void _removeIndividuelleTibZiel(int index) {
    setState(() {
      _individuelleTibZieleControllers[index].dispose();
      _individuelleTibZieleControllers.removeAt(index);
    });
  }

  double? _parseOptionalDouble(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  List<String>? _getIndividuelleTibZiele() {
    final ziele = _individuelleTibZieleControllers
        .map((controller) => controller.text.trim())
        .where((ziel) => ziel.isNotEmpty)
        .toList();
    return ziele.isNotEmpty ? ziele : null;
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final initialDate = _getDateForField(field) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _setDateForField(field, picked);
      });
    }
  }

  DateTime? _getDateForField(String field) {
    switch (field) {
      case 'geburtsdatum':
        return _selectedGeburtsdatum;
      case 'betreuung_seit':
        return _selectedBetreuungSeit;
      case 'kostenuebernahme_von':
        return _selectedKostenuebernahmeVon;
      case 'kostenuebernahme_bis':
        return _selectedKostenuebernahmeBis;
      default:
        return null;
    }
  }

  void _setDateForField(String field, DateTime date) {
    switch (field) {
      case 'geburtsdatum':
        _selectedGeburtsdatum = date;
        break;
      case 'betreuung_seit':
        _selectedBetreuungSeit = date;
        break;
      case 'kostenuebernahme_von':
        _selectedKostenuebernahmeVon = date;
        break;
      case 'kostenuebernahme_bis':
        _selectedKostenuebernahmeBis = date;
        break;
    }
  }

  Future<void> _saveClient(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    try {
      final client = Client.create(
        klientenId: _klientenIdController.text.trim().isNotEmpty ? _klientenIdController.text.trim() : null,
        name: _nameController.text.trim(),
        vorname: _vornameController.text.trim(),
        nachname: _nachnameController.text.trim(),
        berufsgruppe: null, // Berufsgruppe entfernt
        eingliederung: _selectedEingliederung.isEmpty ? null : _selectedEingliederung,
        geburtsdatum: _selectedGeburtsdatum,
        betreuungSeit: _selectedBetreuungSeit,
        kostenuebernahme: _selectedKostentraeger.isEmpty ? null : _selectedKostentraeger,
        kostenuebernahmeVon: _selectedKostenuebernahmeVon,
        kostenuebernahmeBis: _selectedKostenuebernahmeBis,
        fachleistungsstunden: int.tryParse(_fachleistungsstundenController.text),
        fachleistungsIntervall: _selectedIntervall,
        hilfeTyp: _selectedHilfeTyp,
        icfBereiche: null, // Für später implementieren
        verbrauchteStunden: widget.client?.verbrauchteStunden ?? 0.0,
        kalkulationsfaktorOverride: _parseOptionalDouble(_kalkulationsfaktorOverrideController.text),
        stundensatzOverride: _parseOptionalDouble(_stundensatzOverrideController.text),
        vertreter1Id: _selectedVertreter1Id,
        vertreter2Id: _selectedVertreter2Id,
        tibZiele: _selectedTibZiele.isNotEmpty ? _selectedTibZiele : null,
        individuelleTibZiele: _getIndividuelleTibZiele(),
        rechtsgrundlage: _selectedRechtsgrundlage,
      );

      bool success;
      if (widget.client == null) {
        success = await appProvider.addClient(client);
      } else {
        final updatedClient = widget.client!.copyWith(
          klientenId: _klientenIdController.text.trim().isNotEmpty ? _klientenIdController.text.trim() : null,
          name: _nameController.text.trim(),
          vorname: _vornameController.text.trim(),
          nachname: _nachnameController.text.trim(),
          berufsgruppe: null, // Berufsgruppe entfernt
          eingliederung: _selectedEingliederung.isEmpty ? null : _selectedEingliederung,
          geburtsdatum: _selectedGeburtsdatum,
          betreuungSeit: _selectedBetreuungSeit,
          kostenuebernahme: _selectedKostentraeger.isEmpty ? null : _selectedKostentraeger,
          kostenuebernahmeVon: _selectedKostenuebernahmeVon,
          kostenuebernahmeBis: _selectedKostenuebernahmeBis,
          fachleistungsstunden: int.tryParse(_fachleistungsstundenController.text),
          fachleistungsIntervall: _selectedIntervall,
          hilfeTyp: _selectedHilfeTyp,
          kalkulationsfaktorOverride: _parseOptionalDouble(_kalkulationsfaktorOverrideController.text),
          stundensatzOverride: _parseOptionalDouble(_stundensatzOverrideController.text),
          vertreter1Id: _selectedVertreter1Id,
          vertreter2Id: _selectedVertreter2Id,
          tibZiele: _selectedTibZiele.isNotEmpty ? _selectedTibZiele : null,
          individuelleTibZiele: _getIndividuelleTibZiele(),
          rechtsgrundlage: _selectedRechtsgrundlage,
        );
        success = await appProvider.updateClient(updatedClient);
      }

      if (success && context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.client == null
                ? 'Klient erfolgreich erstellt'
                : 'Klient erfolgreich aktualisiert'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}